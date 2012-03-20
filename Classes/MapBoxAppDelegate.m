//
//  MapBoxAppDelegate.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Development Seed 2010. All rights reserved.
//

#import "MapBoxAppDelegate.h"

#import "MapBoxMainViewController.h"

#import "DSMapBoxLegacyMigrationManager.h"
#import "DSMapBoxAlertView.h"
#import "DSMapBoxDownloadManager.h"

#include <sys/xattr.h>

@interface MapBoxAppDelegate ()

@property (nonatomic, strong) DirectoryWatcher *directoryWatcher;

@end

#pragma mark -

@implementation MapBoxAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize directoryWatcher;

- (void)dealloc
{
    [directoryWatcher invalidate];
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
#if ! DEBUG
    [TestFlight takeOff:kTestFlightTeamToken];
#endif

    // legacy data migration
    //
    [[DSMapBoxLegacyMigrationManager defaultManager] migrate];
    
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
    
    // watch for document changes
    //
    self.directoryWatcher = [DirectoryWatcher watchFolderWithPath:[[UIApplication sharedApplication] documentsFolderPath] delegate:self];
    
    // handle launch files & URLs
    //
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
    {
        NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        
        if ([[launchURL scheme] hasPrefix:kMBTilesURLSchemePrefix])
        {
            // in-app MBTiles download remote URLs
            //
            return YES;
        }
        else if ([[NSArray arrayWithObjects:@"kml", @"kmz", @"xml", @"rss", @"geojson", @"json", @"mbtiles", nil] containsObject:[[launchURL pathExtension] lowercaseString]])
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
    
    // kick off downloads (including any just-passed ones)
    //
    [[DSMapBoxDownloadManager sharedManager] performSelector:@selector(resumeDownloads) withObject:nil afterDelay:5.0];
    
    // track number of saved maps
    //
    NSString *savedMapsPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDSSaveFolderName];
    
    int savedMapsCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:savedMapsPath error:NULL] count];
    
    [TestFlight addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", savedMapsCount] forKey:@"Saved Map Count"];
    
	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.viewController saveState:self];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.viewController saveState:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // settings-based defaults resets
    //
    for (__strong NSString *prefKey in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
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
    
    // trigger re-check of iCloud exclusion
    //
    [self directoryDidChange:self.directoryWatcher];
    
    // check pasteboard for supported URLs
    //
    [self.viewController checkPasteboardForURL];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self openExternalURL:url];
}

#pragma mark -

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"excludeiCloudBackup"])
    {
        NSURL *documentsURL = [NSURL fileURLWithPath:[[UIApplication sharedApplication] documentsFolderPath]];
        
        NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:documentsURL
                                                                          includingPropertiesForKeys:nil
                                                                                             options:0
                                                                                        errorHandler:nil];
        
        for (NSURL *enumeratedURL in directoryEnumerator)
        {
            if ([enumeratedURL isFileURL])
            {
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0.1") && SYSTEM_VERSION_LESS_THAN(@"5.1"))
                {
                    const char *filePath = [[enumeratedURL path] fileSystemRepresentation];
                    
                    const char *attrName = "com.apple.MobileBackup"; // attribute means "do not backup"
                    
                    u_int8_t attrValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"excludeiCloudBackup"] ? 1 : 0;
                    
                    setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
                }
                else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.1"))
                {
                    [enumeratedURL setResourceValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"excludeiCloudBackup"] 
                                             forKey:NSURLIsExcludedFromBackupKey 
                                              error:NULL];
                }
            }
        }
    }
}

#pragma mark -

- (BOOL)openExternalURL:(NSURL *)externalURL
{
    // handle in-app MBTiles downloads
    //
    if ([[[externalURL pathExtension] lowercaseString] isEqualToString:@"mbtiles"] && ! [externalURL isFileURL])
    {
        // remove any prefix, leaving normal http: or https: URL
        //
        NSString *downloadURLString = [[externalURL absoluteString] stringByReplacingOccurrencesOfString:@"mb" 
                                                                                              withString:@""
                                                                                                 options:NSAnchoredSearch & NSCaseInsensitiveSearch
                                                                                                   range:NSMakeRange(0, [kMBTilesURLSchemePrefix length])];
        
        // write a unique download file
        //
        NSString *downloadStubFile = [NSString stringWithFormat:@"%@/%@/%@.plist", [[UIApplication sharedApplication] preferencesFolderPath], kDownloadsFolderName, [[NSProcessInfo processInfo] globallyUniqueString]];
        
        NSDictionary *downloadStubContents = [NSDictionary dictionaryWithObject:downloadURLString forKey:@"URL"];
        BOOL success = [downloadStubContents writeToFile:downloadStubFile atomically:NO];
        
        [[DSMapBoxDownloadManager sharedManager] resumeDownloads];
        
        [TestFlight passCheckpoint:@"opened in-app MBTiles download URL"];

        return success;
    }
    
    // download external sources first to prepare for opening locally
    //
    if ( ! [externalURL isFileURL])
    {
        // download in the background to avoid blocking
        //
        NSURLConnection *download = [NSURLConnection connectionWithRequest:[DSMapBoxURLRequest requestWithURL:externalURL]];
        
        download.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];
            
            NSString *downloadPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [externalURL lastPathComponent]];
            
            [responseData writeToFile:downloadPath atomically:YES];
            
            [self openExternalURL:[NSURL fileURLWithPath:downloadPath]];
        };
        
        download.failureBlock = ^(NSURLConnection *connection, NSError *error)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];

            [UIAlertView showAlertViewWithTitle:@"Download Problem"
                                        message:[NSString stringWithFormat:@"There was a problem downloading %@. Would you like to try again?", externalURL]
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:[NSArray arrayWithObject:@"Retry"]
                                        handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                                        {
                                            if (buttonIndex == alertView.firstOtherButtonIndex)
                                                [self openExternalURL:externalURL];
                                        }];
        };
        
        [DSMapBoxNetworkActivityIndicator addJob:download];
        
        [download start];
        
        [TestFlight passCheckpoint:@"opened network URL"];
        
        return YES;
    }
    
    // open the local file
    //
    NSString *lowercaseFilename = [[[externalURL path] lastPathComponent] lowercaseString];
    
    if ([lowercaseFilename hasSuffix:@"kml"] || [lowercaseFilename hasSuffix:@"kmz"])
    {
        [self.viewController openKMLFile:externalURL];

        return YES;
    }
    else if ([lowercaseFilename hasSuffix:@"xml"] || [lowercaseFilename hasSuffix:@"rss"])
    {
        [self.viewController openRSSFile:externalURL];
        
        return YES;
    }
    else if ([lowercaseFilename hasSuffix:@"geojson"] || [lowercaseFilename hasSuffix:@"json"])
    {
        [self.viewController openGeoJSONFile:externalURL];
        
        return YES;
    }
    else if ([lowercaseFilename hasSuffix:@"mbtiles"])
    {
        [self.viewController openMBTilesFile:externalURL];
        
        return YES;
    }
    
    return NO;
}

@end
