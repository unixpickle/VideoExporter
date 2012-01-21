//
//  AppDelegate.h
//  AVExportTest
//
//  Created by Alex Nichol on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoExporter.h"
#import <MediaPlayer/MediaPlayer.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, VideoExporterDelegate> {
    VideoExporter * exporter;
    UIViewController * viewController;
    MPMoviePlayerController * player;
}

@property (strong, nonatomic) UIWindow * window;

@end
