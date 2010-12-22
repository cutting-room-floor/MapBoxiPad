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

    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunVideoPlayed"])
    {
        // tap help button on next run loop pass to allow for device rotation
        //
        [viewController performSelector:@selector(tappedHelpButton:) 
                             withObject:self 
                             afterDelay:0.0];
    }
    else
    {
        if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
        {
            NSURL *incomingURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
            
            if ([[[incomingURL path] lastPathComponent] hasSuffix:@"kml"] || [[[incomingURL path] lastPathComponent] hasSuffix:@"kmz"])
                [viewController openKMLFile:incomingURL];
            
            else
                return NO;
        }
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