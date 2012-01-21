VideoExporter
=============

VideoExporter is a small Objective-C class that wraps AV Foundation's AVAssetWriter in order to export a video file with a sequence of video frames. For more experienced programmers, I would suggest using AV Foundation directly where possible, but this will still provide a good starting point.

To create and start a `VideoExporter`:

	NSURL * pathURL = ...;
    exporter = [[VideoExporter alloc] initWithOutputURL:pathURL size:CGSizeMake(400, 400) frameRate:10];
    [exporter setDelegate:self];
    [exporter beginExport];
    for (int i = 1; i <= 100; i++) {
        UIImage * image = ...;
        [exporter addFrameImage:image];
    }
    [exporter endExport];

Note that the `addFrameImage:` method simply queues the image to be appended to the file. Once all frames have been appended to the video, and the video has been successfully saved, a delegate method will be called:

	- (void)videoExporterFinished:(VideoExporter *)theExporter {
    	NSLog(@"Export finished: %@", [theExporter.outputURL path]);
	}

Note that the `VideoExporter` class only works under ARC, and its owner must retain ownership for as long as the exporter needs to be used.
