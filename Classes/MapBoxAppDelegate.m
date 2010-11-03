//
//  MapBoxAppDelegate.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"
#import "MapBoxMainViewController.h"

@implementation MapBoxAppDelegate

@synthesize window;
@synthesize viewController;

- (void)dealloc
{
    [viewController release];
    [window release];
    
    [super dealloc];
}

#pragma mark -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
    {
        NSURL *incomingURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        
        if ([[[incomingURL path] lastPathComponent] hasSuffix:@"kml"] || [[[incomingURL path] lastPathComponent] hasSuffix:@"kmz"])
            [viewController openKMLFile:incomingURL];
        
        else
            return NO;
    }
        
	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [viewController saveState:self];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [viewController saveState:self];
}

@end