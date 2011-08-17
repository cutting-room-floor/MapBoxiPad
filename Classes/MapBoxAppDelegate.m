//
//  MapBoxAppDelegate.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"

#import "MapBoxMainViewController.h"

#import "MapBoxConstants.h"

#import "DSFingerTipWindow.h"

#import "UIApplication_Additions.h"

#import "DSMapBoxLegacyMigrationManager.h"
#import "DSMapBoxDownloadManager.h"

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
    // legacy data migration
    //
    [[DSMapBoxLegacyMigrationManager defaultManager] migrate];
    
    // main UI setup
    //
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
    
    // handle launch files & URLs
    //
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
    {
        NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        
        if ([[launchURL scheme] hasPrefix:kMBTilesURLSchemePrefix])
        {
            // MBTiles HTTP/HTTPS remote URLs
            //
            return YES;
        }
        else if ([[NSArray arrayWithObjects:@"kml", @"kmz", @"xml", @"rss", @"mbtiles", nil] containsObject:[launchURL pathExtension]])
        {
            // supported file types
            //
            return YES;
        }
        else
        {
            // unsupported launch URL
            //
            return NO;
        }
    }
    
    // kick off downloads (including just-passed ones)
    //
    [DSMapBoxDownloadManager sharedManager];
    
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] hasPrefix:kMBTilesURLSchemePrefix])
    {
        // remove prefix, leaving http: or https: URL
        //
        NSString *downloadURLString = [[url absoluteString] stringByReplacingOccurrencesOfString:kMBTilesURLSchemePrefix withString:@""];
        
        // write a unique download file
        //
        NSString *downloadStubFile = [NSString stringWithFormat:@"%@/%@/%@.plist", [[UIApplication sharedApplication] preferencesFolderPathString], 
                                                                                   kDownloadsFolderName,
                                                                                   [[NSProcessInfo processInfo] globallyUniqueString]];
        
        NSDictionary *downloadStubContents = [NSDictionary dictionaryWithObject:downloadURLString forKey:@"URL"];
        
        return [downloadStubContents writeToFile:downloadStubFile atomically:NO];
    }
    else if ([url isFileURL])
    {
        if ([[url pathExtension] isEqualToString:@"kml"] || [[url pathExtension] isEqualToString:@"kmz"])
        {
            [viewController openKMLFile:url];
            
            return YES;
        }
        else if ([[url pathExtension] isEqualToString:@"xml"] || [[url pathExtension] isEqualToString:@"rss"])
        {
            [viewController openRSSFile:url];
            
            return YES;
        }
        else if ([[url pathExtension] isEqualToString:@"mbtiles"])
        {
            [viewController openMBTilesFile:url];
            
            return YES;
        }
    }
    
    return NO;
}

@end