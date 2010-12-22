//
//  MapBoxAppDelegate.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"
#import "MapBoxMainViewController.h"
#import "UIApplication_Additions.h"

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

    // display help UI on first run
    //
    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunVideoPlayed"])
    {
        // tap help button on next run loop pass to allow for device rotation
        //
        [viewController performSelector:@selector(tappedHelpButton:) 
                             withObject:self 
                             afterDelay:0.0];
    }

    // preload data on first run
    //
    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunDataPreloaded"])
    {
        NSMutableArray *preloadItems = [NSMutableArray array];
        
        for (NSString *extension in [NSArray arrayWithObjects:@"kml", @"kmz", @"rss", nil])
        {
            NSArray *items = [NSBundle pathsForResourcesOfType:extension inDirectory:[[NSBundle mainBundle] resourcePath]];
            
            [preloadItems addObjectsFromArray:items];
        }
        
        for (NSString *item in preloadItems)
            [[NSFileManager defaultManager] copyItemAtPath:item 
                                                    toPath:[NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], [item lastPathComponent]] 
                                                     error:NULL];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstRunDataPreloaded"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
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