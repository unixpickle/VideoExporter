//
//  VideoExporter.h
//  AVExportTest
//
//  Created by Alex Nichol on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VideoExporter;

@protocol VideoExporterDelegate <NSObject>

- (void)videoExporterFinished:(VideoExporter *)exporter;
- (void)videoExporter:(VideoExporter *)exporter failedWithError:(NSError *)aError;

@end

@interface VideoExporter : NSObject {
    uint64_t framesPerSecond;
    int width, height;
    NSURL * outputURL;
    __weak id<VideoExporterDelegate> delegate;
    
    NSLock * endedLock;
    BOOL isEnded;
    uint64_t frameCount;
    NSMutableArray * framesBuffer;
    
    AVAssetWriter * writer;
    AVAssetWriterInput * writerInput;
    AVAssetWriterInputPixelBufferAdaptor * adaptor;
}

@property (readonly) int width, height;
@property (readonly) uint64_t framesPerSecond;
@property (readonly) NSURL * outputURL;
@property (nonatomic, weak) id<VideoExporterDelegate> delegate;

- (id)initWithOutputURL:(NSURL *)aURL size:(CGSize)size frameRate:(uint64_t)fps;

- (void)beginExport;
- (void)addFrameImage:(UIImage *)image;
- (void)endExport;

@end
