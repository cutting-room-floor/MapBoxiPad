//
//  DSMapBoxDownloadManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadManager.h"

@interface DSMapBoxDownloadManager ()

@property (nonatomic, strong) NSMutableArray *downloads;           // all NSURLConnection objects
@property (nonatomic, strong) NSMutableArray *pausedDownloads;     // paused NSURLConnection objects
@property (nonatomic, strong) NSMutableArray *backgroundDownloads; // NSNumber objects containing background task IDs
@property (nonatomic, strong) NSMutableArray *progresses;          // NSNumber objects tracking download progress (floats)
@property (nonatomic, readonly, strong) NSString *downloadsPath;   // path to download folder on disk
@property (nonatomic, readonly, strong) NSArray *pendingDownloads; // full paths to download stub plists left on disk

- (NSString *)identifierForDownload:(NSURLConnection *)download;
- (void)downloadURL:(NSURL *)downloadURL resumingDownload:(NSURLConnection *)pausedDownload;
- (void)unregisterBackgroundDownload:(NSURLConnection *)download;

@end

#pragma mark -

@implementation DSMapBoxDownloadManager

@synthesize downloads;
@synthesize pausedDownloads;
@synthesize backgroundDownloads;
@synthesize progresses;
@synthesize downloadsPath;

+ (DSMapBoxDownloadManager *)sharedManager
{
    static dispatch_once_t token;
    static DSMapBoxDownloadManager *sharedManager = nil;
    
    dispatch_once(&token, ^{ sharedManager = [[self alloc] init]; });
    
    return sharedManager;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        downloads           = [NSMutableArray array];
        pausedDownloads     = [NSMutableArray array];
        backgroundDownloads = [NSMutableArray array];
        progresses          = [NSMutableArray array];
        
        downloadsPath       = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDownloadsFolderName];
        
        BOOL isDir;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:downloadsPath isDirectory:&isDir] || ! isDir)
        {
            [[NSFileManager defaultManager] removeItemAtPath:downloadsPath error:NULL];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:downloadsPath
                                      withIntermediateDirectories:NO 
                                                       attributes:nil
                                                            error:NULL];
        }
    }
    
    return self;
}

#pragma mark -

- (NSArray *)pendingDownloads
{
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.downloadsPath error:NULL];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    for (NSString *path in paths)
        if ([[path pathExtension] isEqualToString:@"plist"])
            [fullPaths addObject:[NSString stringWithFormat:@"%@/%@", self.downloadsPath, path]];
    
    return [NSArray arrayWithArray:fullPaths];
}

- (NSString *)identifierForDownload:(NSURLConnection *)download
{
    NSString *path = [self.pendingDownloads match:^(id obj)
                     {
                         return [[[NSDictionary dictionaryWithContentsOfFile:obj] objectForKey:@"URL"] isEqualToString:[download.originalRequest.URL absoluteString]];
                     }];
    
    return [[path lastPathComponent] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
}

- (void)downloadURL:(NSURL *)downloadURL resumingDownload:(NSURLConnection *)pausedDownload
{
    // setup the connection
    //
    NSURLConnection *download = [NSURLConnection connectionWithRequest:[DSMapBoxURLRequest requestWithURL:downloadURL]];
    
    download.delegate = self;
    
    // TODO: add HTTP resume header

    if (pausedDownload)
    {
        // replace old download in master downloads list
        //
        [self.downloads replaceObjectAtIndex:[self.downloads indexOfObject:pausedDownload] 
                                  withObject:download];
        
        // cancel & cleanup old download (progress tracking will just get updated in place by new download)
        //
        [pausedDownload cancel];
        [DSMapBoxNetworkActivityIndicator removeJob:pausedDownload];
        [self unregisterBackgroundDownload:pausedDownload];
    }
    else
    {
        // add new download to master downloads list, background jobs, and progress tracking
        //
        [self.downloads addObject:download];
        [self.backgroundDownloads addObject:[NSNumber numberWithUnsignedInteger:UIBackgroundTaskInvalid]];
        [self.progresses addObject:[NSNumber numberWithFloat:0.0]];
    }
    
    // start tracking new download in UI
    //
    [DSMapBoxNetworkActivityIndicator addJob:download];

    // create background task with its cleanup handler
    //
    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"noBackgroundDownloads"] || ! [[NSUserDefaults standardUserDefaults] boolForKey:@"noBackgroundDownloads"])
    {
        UIBackgroundTaskIdentifier taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void)
                                            {
                                                // find the task ID amongst the active background ones
                                                //
                                                int match = -1;
                                                int i;
                                                
                                                for (i = 0; i < [self.backgroundDownloads count]; i++)
                                                {
                                                    if ([[self.backgroundDownloads objectAtIndex:i] unsignedIntegerValue] == taskID)
                                                    {
                                                        match = i;
                                                        break;
                                                    }
                                                }
                                                
                                                // find & pause the download corresponding to the same index in the downloads list (if we found it)
                                                //
                                                if (match >= 0)
                                                    [self pauseDownload:[self.downloads objectAtIndex:match]]; // also handles background task cleanup
                                            }];
        
        // update background task list with new ID
        //
        [self.backgroundDownloads replaceObjectAtIndex:[self.downloads indexOfObject:download] 
                                            withObject:[NSNumber numberWithUnsignedInteger:taskID]];
    }
    
    // start the new download
    //
    [download start];
}

- (void)unregisterBackgroundDownload:(NSURLConnection *)download
{
    if ([self.downloads containsObject:download])
    {
        // proceed only for active downloads
        //
        int i = [self.downloads indexOfObject:download];
        
        if ([[self.backgroundDownloads objectAtIndex:i] unsignedIntegerValue] != UIBackgroundTaskInvalid)
        {
            // proceed only for valid background tasks
            //
            [[UIApplication sharedApplication] endBackgroundTask:[[self.backgroundDownloads objectAtIndex:i] unsignedIntegerValue]];
            
            [self.backgroundDownloads replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedInteger:UIBackgroundTaskInvalid]];
        }
    }
}

#pragma mark -

- (void)resumeDownloads
{
    // find stub files with duplicate URLs
    //
    NSMutableArray *duplicates = [NSMutableArray array];
    
    for (NSString *downloadStubFile in self.pendingDownloads)
    {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:downloadStubFile];
        
        NSURL *downloadURL = [NSURL URLWithString:[info objectForKey:@"URL"]];        
        
        if ([[self.downloads valueForKeyPath:@"originalRequest.URL"] containsObject:downloadURL])
        {
            [duplicates addObject:downloadStubFile];
        }
        else
        {
            // TODO: also resume paused downloads
            
            [self downloadURL:downloadURL resumingDownload:nil]; 
        }
    }
    
    // delete duplicate stub files
    //
    for (NSString *dupe in duplicates)
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, dupe] error:NULL];
    
    // notify that download queue has changed
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:([self.downloads count] ? YES : NO)]];
}

#pragma mark -

- (void)pauseDownload:(NSURLConnection *)download
{
    NSLog(@"pausing %@", download.originalRequest.URL);
    
    [self.pausedDownloads addObject:download];

    [download cancel];
    
    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundDownload:download];

    [TESTFLIGHT passCheckpoint:@"paused MBTiles download"];
}

- (void)resumeDownload:(NSURLConnection *)download
{
    NSLog(@"resuming %@", download.originalRequest.URL);
   
    [self.pausedDownloads removeObject:download];
    
    [self downloadURL:download.originalRequest.URL resumingDownload:download];
    
    [TESTFLIGHT passCheckpoint:@"resumed MBTiles download"];
}

- (void)cancelDownload:(NSURLConnection *)download
{
    NSLog(@"cancelling %@", download.originalRequest.URL);
    
    [download cancel];

    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundDownload:download];
    
    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:download]];
    [self.downloads  removeObject:download];

    NSString *identifier = [self identifierForDownload:download];
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, identifier, kPartialDownloadExtension] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, identifier] error:NULL];
    
    [TESTFLIGHT passCheckpoint:@"cancelled MBTiles download"];
}

- (BOOL)downloadIsPaused:(NSURLConnection *)download
{
    NSLog(@"checking pause status for %@", download.originalRequest.URL);
    
    return [self.pausedDownloads containsObject:download];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *webResponse = (NSHTTPURLResponse *)response;
    
    NSLog(@"connected %@ with HTTP %i", connection.originalRequest.URL, webResponse.statusCode);
    
    if ([[webResponse allHeaderFields] objectForKey:@"Content-Length"])
    {
        // update expected size if given
        //
        NSInteger length = [[[webResponse allHeaderFields] objectForKey:@"Content-Length"] integerValue];
        
        NSString *downloadStubFile = [NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, [self identifierForDownload:connection]];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:downloadStubFile];
        
        [info setObject:[NSNumber numberWithInteger:length] forKey:@"Size"];
        
        [info writeToFile:downloadStubFile atomically:YES];
    }
    
    // TODO: resume
    
    NSString *downloadPath = [NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, [self identifierForDownload:connection], kPartialDownloadExtension];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL]; // FIXME
    
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:downloadPath])
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:[NSData data] attributes:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"failed %@: %@", connection.originalRequest.URL, error);

    [DSMapBoxNetworkActivityIndicator removeJob:connection];

    // pause, leaving partial file to possibly resume
    //
    [self pauseDownload:connection];

    [TESTFLIGHT passCheckpoint:@"failed MBTiles download"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // find partial download & prepare to append
    //
    NSString *identifier = [self identifierForDownload:connection];
    
    NSString *downloadPath = [NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, identifier, kPartialDownloadExtension];

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:downloadPath];
    
    [handle seekToEndOfFile];
    
    unsigned long long totalDownloaded = [handle offsetInFile] + [data length];
    
    // update progress tracking
    //
    // FIXME: need indetermine progress indication
    //
    NSInteger totalSize = [[[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, identifier]] objectForKey:@"Size"] integerValue];
    
    CGFloat thisProgress = (CGFloat)totalDownloaded / (CGFloat)totalSize;
    
    [self.progresses replaceObjectAtIndex:[self.downloads indexOfObject:connection] withObject:[NSNumber numberWithFloat:thisProgress]];
    
    // post individual progress
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification 
                                                        object:connection
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:thisProgress] 
                                                                                           forKey:DSMapBoxDownloadProgressKey]];
    
    // post aggregate progress
    //
    CGFloat overallProgress = 0.0;
    
    for (NSNumber *progress in self.progresses)
        overallProgress += [progress floatValue];
    
    overallProgress = overallProgress / [self.progresses count];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification 
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:overallProgress]
                                                                                           forKey:DSMapBoxDownloadProgressKey]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [DSMapBoxNetworkActivityIndicator removeJob:connection];

    NSString *downloadedFile = [NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, [self identifierForDownload:connection], kPartialDownloadExtension];
    
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:downloadedFile error:NULL];
    
    NSLog(@"finished %@ to %@ at size %@", connection.originalRequest.URL, downloadedFile, [info objectForKey:NSFileSize]);

    // remove stub file since we're done with it
    //
    NSString *path = [self.pendingDownloads match:^(id obj)
                     {
                         return [[[NSDictionary dictionaryWithContentsOfFile:obj] objectForKey:@"URL"] isEqualToString:[connection.originalRequest.URL absoluteString]];
                     }];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    // clean up progress & downloads lists
    //
    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:connection]];
    [self.downloads  removeObject:connection];
    
    // move completed download into place, accounting for duplicate(s)
    //
    NSString *filename  = [connection.originalRequest.URL lastPathComponent];
    NSString *extension = [filename pathExtension];
    NSString *basename  = [filename stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", extension] 
                                                              withString:@""
                                                                 options:NSAnchoredSearch & NSBackwardsSearch 
                                                                   range:NSMakeRange(0, [filename length])]; 
    
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPath], filename];
    
    int i = 2;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
    {
        destinationPath = [NSString stringWithFormat:@"%@/%@ %i.%@", [[UIApplication sharedApplication] documentsFolderPath], basename, i, extension];
        
        i++;
    }
    
    [[NSFileManager defaultManager] moveItemAtPath:downloadedFile 
                                            toPath:destinationPath
                                             error:NULL];
    
    // post notification of completion
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadCompleteNotification object:connection];
    
    // check if we're the last pending download & post queue update
    //
    if ([self.downloads count] == 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:NO]];
    
    // give a sec for UI to update, then invalidate background job
    //
    dispatch_delayed_ui_action(1.0, ^(void)
    {
        [self unregisterBackgroundDownload:connection];
    });
    
    [TESTFLIGHT passCheckpoint:@"completed MBTiles download"];
}

@end