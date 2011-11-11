//
//  MapBoxAppDelegate.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Development Seed 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"

#import "MapBoxMainViewController.h"

#import "UIApplication_Additions.h"

#import "DSMapBoxLegacyMigrationManager.h"
#import "DSMapBoxAlertView.h"

#import "ASIHTTPRequest.h"

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
    // set build version for settings bundle
    //
    NSString *majorVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""];

    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@.%@", majorVersion, minorVersion] forKey:@"buildVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // begin TestFlight tracking
    //
    [TESTFLIGHT takeOff:kTestFlightTeamToken];
    
    // legacy data migration
    //
    [[DSMapBoxLegacyMigrationManager defaultManager] migrate];
    
    // main UI setup
    //
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];

    // display help UI on first run
    //
    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunVideoPlayed"])
    {
        // tap help button on next run loop pass to allow for device rotation
        //
        [self.viewController performSelector:@selector(tappedHelpButton:) 
                                  withObject:self 
                                  afterDelay:0.0];
    }

    // preload data on first run
    //
    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunDataPreloaded"])
    {
        NSMutableArray *preloadItems = [NSMutableArray array];
        
        // data layers
        //
        for (NSString *extension in [NSArray arrayWithObjects:@"kml", @"kmz", @"rss", nil])
        {
            NSArray *items = [NSBundle pathsForResourcesOfType:extension inDirectory:[[NSBundle mainBundle] resourcePath]];
            
            [preloadItems addObjectsFromArray:items];
        }
        
        for (NSString *item in preloadItems)
            [[NSFileManager defaultManager] copyItemAtPath:item 
                                                    toPath:[NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPath], [item lastPathComponent]] 
                                                     error:NULL];
        
        // tile layers
        //
        for (NSString *extension in [NSArray arrayWithObjects:@"plist", nil])
        {
            NSArray *items = [NSBundle pathsForResourcesOfType:extension inDirectory:[[NSBundle mainBundle] resourcePath]];
            
            [preloadItems addObjectsFromArray:items];
        }
        
        for (NSString *item in preloadItems)
            if ([[NSDictionary dictionaryWithContentsOfFile:item] objectForKey:@"basename"])
                [[NSFileManager defaultManager] copyItemAtPath:item 
                                                        toPath:[NSString stringWithFormat:@"%@/%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kTileStreamFolderName, [item lastPathComponent]] 
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

        return [self openExternalURL:[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]];
    }
    
#if BETA_TESTING
    // track number of saved maps
    //
    NSString *savedMapsPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDSSaveFolderName];
    
    int savedMapsCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:savedMapsPath error:NULL] count];
    
    [TESTFLIGHT addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", savedMapsCount] forKey:@"Saved Map Count"];
#endif
    
	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.viewController saveState:self];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.viewController saveState:self];
    
    // For 4.2+, mark that we are no longer processing an external file.
    //
    self.openingExternalFile = NO;
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
    [self.viewController checkPasteboardForURL];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ( ! self.openingExternalFile)
    {
        // For 4.2+, mark that we've already got this file. This shouldn't be necessary, but why chance it.
        //
        self.openingExternalFile = YES;

        return [self openExternalURL:url];
    }
    
    return YES;
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
        
        [TESTFLIGHT passCheckpoint:@"opened mbhttp: URL"];
    }    
    
    // download external sources first to prepare for opening locally
    //
    if ( ! [externalURL isFileURL])
    {
        // we'll do this in the background to avoid blocking
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
        
        [TESTFLIGHT passCheckpoint:@"opened network URL"];
        
        return YES;
    }
    
    // open the local file
    //
    if ([[[externalURL path] lastPathComponent] hasSuffix:@"kml"] || [[[externalURL path] lastPathComponent] hasSuffix:@"kmz"])
    {
        [self.viewController openKMLFile:externalURL];

        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"xml"] || [[[externalURL path] lastPathComponent] hasSuffix:@"rss"])
    {
        [self.viewController openRSSFile:externalURL];
        
        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"geojson"] || [[[externalURL path] lastPathComponent] hasSuffix:@"json"])
    {
        [self.viewController openGeoJSONFile:externalURL];
        
        return YES;
    }
    else if ([[[externalURL path] lastPathComponent] hasSuffix:@"mbtiles"])
    {
        [self.viewController openMBTilesFile:externalURL];
        
        return YES;
    }
    
    return NO;
}

@end