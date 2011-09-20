//
//  MapBoxAppDelegate.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"

#import "MapBoxConstants.h"
#import "MapBoxMainViewController.h"

#import "DSFingerTipWindow.h"

#import "UIApplication_Additions.h"

#import "DSMapBoxLegacyMigrationManager.h"
#import "DSMapBoxAlertView.h"
#import "DSMapBoxDownloadManager.h"

#import "ASIHTTPRequest.h"

#import "TestFlight.h"

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
    // begin TestFlight tracking
    //
#ifndef DEBUG
    [TestFlight takeOff:kTestFlightTeamToken];
#endif
    
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

    // if launched via URL, make sure we support it
    //
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] && ! [kSupportedFileExtensions containsObject:[[[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] pathExtension] lowercaseString]])
        return NO;

    // kick off old downloads
    //
    [[DSMapBoxDownloadManager sharedManager] resumeDownloads];

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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // settings-based defaults resets
    //
    for (NSString *prefKey in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
    {
        if ([prefKey hasPrefix:@"reset"] && [[NSUserDefaults standardUserDefaults] boolForKey:prefKey])
        {
            // remove 'resetFooBar' to mark it done
            //
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefKey];
            
            // remove 'fooBar' to actually reset
            //
            prefKey = [prefKey stringByReplacingOccurrencesOfString:@"reset"
                                                         withString:@""
                                                            options:NSAnchoredSearch
                                                              range:NSMakeRange(0, 5)];
            
            prefKey = [prefKey stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
                                                       withString:[[prefKey substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefKey];
        }
    }
    
    // check pasteboard for supported URLs
    //
    [viewController checkPasteboardForURL];
    
    // resume downloads
    //
    [[DSMapBoxDownloadManager sharedManager] resumeDownloads];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self openExternalURL:url];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        NSURL *externalURL = (NSURL *)((DSMapBoxAlertView *)alertView).context;
        
        [self openExternalURL:externalURL];
    }
}

#pragma mark -

- (BOOL)openExternalURL:(NSURL *)externalURL
{
    // convert mbhttp/mbhttps as necessary
    //
    if ([[externalURL scheme] hasPrefix:@"mbhttp"])
    {
        externalURL = [NSURL URLWithString:[[externalURL absoluteString] stringByReplacingOccurrencesOfString:@"mb"
                                                                                                   withString:@""
                                                                                                      options:NSAnchoredSearch
                                                                                                        range:NSMakeRange(0, 10)]];
        
        [TestFlight passCheckpoint:@"opened mbhttp: URL"];
    }
    
    // download external sources first to prepare for opening locally
    //
    if ( ! [externalURL isFileURL])
    {
        // handle MBTiles files in download queue
        //
        if ([[[externalURL pathExtension] lowercaseString] isEqualToString:@"mbtiles"])
        {
            NSString *downloadStubFile = [NSString stringWithFormat:@"%@/%@/%@.plist", [[UIApplication sharedApplication] preferencesFolderPathString], 
                                                                                       kDownloadsFolderName,
                                                                                       [[NSProcessInfo processInfo] globallyUniqueString]];

            NSDictionary *downloadStubContents = [NSDictionary dictionaryWithObject:[externalURL absoluteString] forKey:@"URL"];

            BOOL success = [downloadStubContents writeToFile:downloadStubFile atomically:NO];

            [[DSMapBoxDownloadManager sharedManager] resumeDownloads];

            return success;
        }
        
        // otherwise, download ourselves in the background to avoid blocking
        //
        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:externalURL];
        
        // download to disk
        //
        [request setDownloadDestinationPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [externalURL lastPathComponent]]];
        
        // retry as local file when complete
        //
        [request setCompletionBlock:^(void)
        {
            [self openExternalURL:[NSURL fileURLWithPath:request.downloadDestinationPath]];
        }];
        
        // re-prompt on failure
        //
        [request setFailedBlock:^(void)
        {
            DSMapBoxAlertView *alert = [[[DSMapBoxAlertView alloc] initWithTitle:@"Download Problem"
                                                                         message:[NSString stringWithFormat:@"There was a problem downloading %@. Would you like to try again?", externalURL]
                                                                        delegate:self
                                                               cancelButtonTitle:@"Cancel"
                                                               otherButtonTitles:@"Retry", nil] autorelease];
            
            alert.context = externalURL;
            
            [alert show];
        }];
        
        [request startAsynchronous];
        
        [TestFlight passCheckpoint:@"opened network URL"];
        
        return YES;
    }
    
    // open the local file
    //
    if ([[[externalURL path] lastPathComponent] hasSuffix:@"kml"] || [[[externalURL path] lastPathComponent] hasSuffix:@"kmz"])
    {
        [viewController openKMLFile:externalURL];

        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"xml"] || [[[externalURL path] lastPathComponent] hasSuffix:@"rss"])
    {
        [viewController openRSSFile:externalURL];
        
        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"geojson"] || [[[externalURL path] lastPathComponent] hasSuffix:@"json"])
    {
        [viewController openGeoJSONFile:externalURL];
        
        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"mbtiles"])
    {
        [viewController openMBTilesFile:externalURL];
        
        return YES;
    }
    
    return NO;
}

@end