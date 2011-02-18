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

@interface MapBoxAppDelegate (MapBoxAppDelegatePrivate)

- (BOOL)openFileURL:(NSURL *)fileURL;

@end

#pragma mark -

@implementation MapBoxAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize openingExternalFile;

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
        // Note that we are opening a file so that application:openURL:sourceApplication:annotation:
        // doesn't also get called on 4.2+ for this file.
        //
        self.openingExternalFile = YES;

        return [self openFileURL:[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]];
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
    
    // For 4.2+, mark that we are no longer processing an external file.
    //
    self.openingExternalFile = NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ( ! self.openingExternalFile)
    {
        // For 4.2+, mark that we've already got this file. This shouldn't be necessary, but why chance it.
        //
        self.openingExternalFile = YES;

        return [self openFileURL:url];
    }
    
    return YES;
}

#pragma mark -

- (BOOL)openFileURL:(NSURL *)fileURL
{
    if ([[[fileURL path] lastPathComponent] hasSuffix:@"kml"] || [[[fileURL path] lastPathComponent] hasSuffix:@"kmz"])
    {
        [viewController openKMLFile:fileURL];

        return YES;
    }
    else if ([[[fileURL path] lastPathComponent] hasSuffix:@"xml"] || [[[fileURL path] lastPathComponent] hasSuffix:@"rss"])
    {
        [viewController openRSSFile:fileURL];
        
        return YES;
    }
    
    return NO;
}

@end