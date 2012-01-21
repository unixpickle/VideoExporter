//
//  VideoExporter.m
//  AVExportTest
//
//  Created by Alex Nichol on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideoExporter.h"

@interface VideoExporter (Private)

- (void)exportBlockMethod;
- (void)handleSessionComplete;
- (void)handleSessionError:(NSError *)error;
- (CVPixelBufferRef)pixelBufferForImage:(UIImage *)image;

@end

@implementation VideoExporter

@synthesize width, height;
@synthesize framesPerSecond;
@synthesize outputURL;
@synthesize delegate;

- (id)initWithOutputURL:(NSURL *)aURL size:(CGSize)size frameRate:(uint64_t)fps {
    if ((self = [super init])) {
        width = (int)round(size.width);
        height = (int)round(size.height);
        framesPerSecond = fps;
        outputURL = aURL;
        
        endedLock = [[NSLock alloc] init];
        framesBuffer = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)beginExport {
    if (writer || writerInput || adaptor) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Export session already begun" userInfo:nil];
    }
    
    writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                       fileType:AVFileTypeQuickTimeMovie
                                          error:nil];

    NSDictionary * outSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                  [NSNumber numberWithInt:width], AVVideoWidthKey,
                                  [NSNumber numberWithInt:height], AVVideoHeightKey, nil];
    writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outSettings];

    NSDictionary * pixelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    adaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:pixelAttributes];

    [writer addInput:writerInput];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];

    dispatch_queue_t dispatchQueue = dispatch_queue_create("inputQueue", NULL);
    __block id selfBlock = self;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^ {
        [selfBlock exportBlockMethod];
    }];
    dispatch_release(dispatchQueue);
}

- (void)addFrameImage:(UIImage *)image {
    @synchronized (framesBuffer) {
        [framesBuffer addObject:image];
    }
}

- (void)endExport {
    [endedLock lock];
    if (isEnded) {
        [endedLock unlock];
        @throw [NSException exceptionWithName:NSGenericException reason:@"Export session is already ended." userInfo:nil];
    }
    isEnded = YES;
    [endedLock unlock];
}

#pragma mark - Private -

- (void)exportBlockMethod {
    while ([writerInput isReadyForMoreMediaData]) {
        // Wait until a frame has been queued or the exporter
        // has been ended.
        while (true) {
            BOOL endedVal = NO;
            @synchronized (framesBuffer) {
                if ([framesBuffer count] > 0) {
                    break;
                }
                [endedLock lock];
                endedVal = isEnded;
                [endedLock unlock];
            }
            
            if (endedVal) {
                // no more input will be supplied
                [writerInput markAsFinished];
                if ([writer finishWriting]) {
                    [self performSelectorOnMainThread:@selector(handleSessionComplete) withObject:nil waitUntilDone:NO];
                } else {
                    NSError * error = [writer error];
                    [self performSelectorOnMainThread:@selector(handleSessionError:) withObject:error waitUntilDone:NO];
                }
                return;
            }
            
            // If the track has not been ended, we will wait 100ms before checking
            // if more frames have been queued.
            [NSThread sleepForTimeInterval:0.1];
        }
        
        // Get the next frame in the queue
        UIImage * imageFrame = nil;
        @synchronized (framesBuffer) {
            imageFrame = [framesBuffer objectAtIndex:0];
            [framesBuffer removeObjectAtIndex:0];
        }
        
        // Generate the pixel buffer for the next frame
        CVPixelBufferRef pixelBuff = [self pixelBufferForImage:imageFrame];
        if (!pixelBuff) {
            NSDictionary * dictionary = [NSDictionary dictionaryWithObject:@"Failed to create pixel buffer for frame."
                                                                    forKey:NSLocalizedDescriptionKey];
            NSError * error = [NSError errorWithDomain:@"VideoExporterError" code:1 userInfo:dictionary];
            [self performSelectorOnMainThread:@selector(handleSessionError:) withObject:error waitUntilDone:NO];
            return;
        }
        
        NSLog(@"Adding frame");
        
        // Add the pixel buffer to the asset by writing it to the adaptor, which in turn
        // writes to the input writer, which writes to the asset writer.
        if (![adaptor appendPixelBuffer:pixelBuff withPresentationTime:CMTimeMake(frameCount++, framesPerSecond)]) {
            CFRelease(pixelBuff);
            NSDictionary * dictionary = [NSDictionary dictionaryWithObject:@"Failed to append pixel buffer."
                                                                    forKey:NSLocalizedDescriptionKey];
            NSError * error = [NSError errorWithDomain:@"VideoExporterError" code:2 userInfo:dictionary];
            [self performSelectorOnMainThread:@selector(handleSessionError:) withObject:error waitUntilDone:NO];
            return;
        }
        
        CFRelease(pixelBuff);
    }
}

- (void)handleSessionComplete {
    //dispatch_release(dispatchQueue);
    //dispatchQueue = NULL;
    writer = nil;
    writerInput = nil;
    adaptor = nil;
    if ([delegate respondsToSelector:@selector(videoExporterFinished:)]) {
        [delegate videoExporterFinished:self];
    }
}

- (void)handleSessionError:(NSError *)error {
    [writer cancelWriting];
    writer = nil;
    writerInput = nil;
    adaptor = nil;
    //dispatch_release(dispatchQueue);
    //dispatchQueue = NULL;
    if ([delegate respondsToSelector:@selector(videoExporter:failedWithError:)]) {
        [delegate videoExporter:self failedWithError:error];
    }
}

- (CVPixelBufferRef)pixelBufferForImage:(UIImage *)image {
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool, &pixelBuffer);
        
    if (status != 0) return NULL;
    
    uint64_t pixelsWide = CVPixelBufferGetWidth(pixelBuffer);
    uint64_t pixelsHigh = CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void * pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // draw the image on the pixel data
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, pixelsWide, pixelsHigh, 8, 4 * pixelsWide, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage = [image CGImage];
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

@end
