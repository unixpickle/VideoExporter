//
//  AppDelegate.m
//  AVExportTest
//
//  Created by Alex Nichol on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    viewController = [[UIViewController alloc] init];
    [viewController.view setBackgroundColor:[UIColor grayColor]];
    UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator setCenter:CGPointMake(viewController.view.frame.size.width / 2, viewController.view.frame.size.height / 2)];
    [activityIndicator startAnimating];
    [viewController.view addSubview:activityIndicator];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];
    
    NSString * path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"video.mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    NSURL * pathURL = [NSURL fileURLWithPath:path];
    
    exporter = [[VideoExporter alloc] initWithOutputURL:pathURL size:CGSizeMake(400, 400) frameRate:10];
    [exporter setDelegate:self];
    [exporter beginExport];
    for (int i = 1; i <= 44; i++) {
        UIImage * image = [UIImage imageNamed:[NSString stringWithFormat:@"frame%d.png", i]];
        [exporter addFrameImage:image];
    }
    [exporter endExport];
    
    return YES;
}

- (void)videoExporter:(VideoExporter *)exporter failedWithError:(NSError *)aError {
    NSLog(@"Export failed: %@", aError);
}

- (void)videoExporterFinished:(VideoExporter *)theExporter {
    NSLog(@"Export finished: %@", [theExporter.outputURL path]);
    player = [[MPMoviePlayerController alloc] initWithContentURL:theExporter.outputURL];
    player.controlStyle = MPMovieControlStyleFullscreen;
    [player prepareToPlay];
    [player.view setFrame:viewController.view.bounds];
    [viewController.view addSubview:player.view];
    [player play];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
