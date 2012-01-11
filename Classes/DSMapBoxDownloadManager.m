//
//  DSMapBoxDownloadManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadManager.h"

static const char *DSMapBoxDownloadManagerDownloadIsPaused        = "DSMapBoxDownloadManagerDownloadIsPaused";
static const char *DSMapBoxDownloadManagerDownloadIsIndeterminate = "DSMapBoxDownloadManagerDownloadIsIndeterminate";

@interface NSURLConnection (DSMapBoxDownloadManagerPrivate)

- (void)setIsPaused:(BOOL)flag;
- (void)setIsIndeterminate:(BOOL)flag;

@end

#pragma mark -

@implementation NSURLConnection (DSMapBoxDownloadManager)

- (BOOL)isPaused
{
    return [[self associatedValueForKey:DSMapBoxDownloadManagerDownloadIsPaused] boolValue];
}

- (void)setIsPaused:(BOOL)flag
{
    [self associateValue:[NSNumber numberWithBool:flag] withKey:DSMapBoxDownloadManagerDownloadIsPaused];
}

- (BOOL)isIndeterminate
{
    return [[self associatedValueForKey:DSMapBoxDownloadManagerDownloadIsIndeterminate] boolValue];
}

- (void)setIsIndeterminate:(BOOL)flag
{
    [self associateValue:[NSNumber numberWithBool:flag] withKey:DSMapBoxDownloadManagerDownloadIsIndeterminate];
}

@end

#pragma mark -

@interface DSMapBoxDownloadManager ()

@property (nonatomic, strong) NSMutableArray *downloads;           // NSURLConnection objects
@property (nonatomic, strong) NSMutableArray *backgroundTasks;     // NSNumber objects containing background task IDs
@property (nonatomic, strong) NSMutableArray *progresses;          // NSNumber objects tracking download progress (floats)
@property (nonatomic, readonly, strong) NSString *downloadsPath;   // path to download folder on disk
@property (nonatomic, readonly, strong) NSArray *pendingDownloads; // full paths to download stub plists left on disk

- (NSString *)identifierForDownload:(NSURLConnection *)download;
- (void)downloadURL:(NSURL *)downloadURL resumingDownload:(NSURLConnection *)pausedDownload;
- (void)unregisterBackgroundTaskForDownload:(NSURLConnection *)download;

@end

#pragma mark -

@implementation DSMapBoxDownloadManager

@synthesize downloads;
@synthesize backgroundTasks;
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
        downloads       = [NSMutableArray array];
        backgroundTasks = [NSMutableArray array];
        progresses      = [NSMutableArray array];
        
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
        [self unregisterBackgroundTaskForDownload:pausedDownload];
    }
    else
    {
        // add new download to master downloads list, background jobs, and progress tracking
        //
        [self.downloads addObject:download];
        [self.backgroundTasks addObject:[NSNumber numberWithUnsignedInteger:UIBackgroundTaskInvalid]];
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
                                                
                                                for (i = 0; i < [self.backgroundTasks count]; i++)
                                                {
                                                    if ([[self.backgroundTasks objectAtIndex:i] unsignedIntegerValue] == taskID)
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
        [self.backgroundTasks replaceObjectAtIndex:[self.downloads indexOfObject:download] 
                                        withObject:[NSNumber numberWithUnsignedInteger:taskID]];
    }
    
    // start the new download
    //
    [download start];
}

- (void)unregisterBackgroundTaskForDownload:(NSURLConnection *)download
{
    if ([self.downloads containsObject:download])
    {
        // proceed only for active downloads
        //
        int i = [self.downloads indexOfObject:download];
        
        if ([[self.backgroundTasks objectAtIndex:i] unsignedIntegerValue] != UIBackgroundTaskInvalid)
        {
            // proceed only for valid background tasks
            //
            [[UIApplication sharedApplication] endBackgroundTask:[[self.backgroundTasks objectAtIndex:i] unsignedIntegerValue]];
            
            [self.backgroundTasks replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedInteger:UIBackgroundTaskInvalid]];
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
    
    download.isPaused = YES;

    [download cancel];
    
    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundTaskForDownload:download];

    [TESTFLIGHT passCheckpoint:@"paused MBTiles download"];
}

- (void)resumeDownload:(NSURLConnection *)download
{
    NSLog(@"resuming %@", download.originalRequest.URL);
   
    download.isPaused = NO;
    
    [self downloadURL:download.originalRequest.URL resumingDownload:download];
    
    [TESTFLIGHT passCheckpoint:@"resumed MBTiles download"];
}

- (void)cancelDownload:(NSURLConnection *)download
{
    NSLog(@"cancelling %@", download.originalRequest.URL);
    
    [download cancel];

    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundTaskForDownload:download];
    
    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:download]];
    [self.downloads  removeObject:download];

    NSString *identifier = [self identifierForDownload:download];
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, identifier, kPartialDownloadExtension] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, identifier] error:NULL];
    
    [TESTFLIGHT passCheckpoint:@"cancelled MBTiles download"];
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
    else
        connection.isIndeterminate = YES;
    
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
    
    // append data & close
    //
    [handle writeData:data];
    [handle closeFile];
    
    // update progress tracking if possible
    //
    CGFloat thisProgress = 0.0;
    NSUInteger totalSize = 0.0;
    
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, identifier]];
    
    if ( ! connection.isIndeterminate)
    {
        totalSize = [[info objectForKey:@"Size"] integerValue];
        
        thisProgress = (CGFloat)totalDownloaded / (CGFloat)totalSize;
        
        [self.progresses replaceObjectAtIndex:[self.downloads indexOfObject:connection] withObject:[NSNumber numberWithFloat:thisProgress]];
    }
    
    // post individual progress
    //
    NSDictionary *progressDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:thisProgress], DSMapBoxDownloadProgressKey,
                                                                                  [NSNumber numberWithUnsignedInteger:totalDownloaded], DSMapBoxDownloadTotalDownloadedKey, 
                                                                                  [NSNumber numberWithUnsignedInteger:totalSize], DSMapBoxDownloadTotalSizeKey,
                                                                                  nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification 
                                                        object:connection
                                                      userInfo:progressDictionary];

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

    // post individual progress completion
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification 
                                                        object:connection
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] 
                                                                                           forKey:DSMapBoxDownloadProgressKey]];
    
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
    
    NSString *downloadedFile = [NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, [self identifierForDownload:connection], kPartialDownloadExtension];

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
    [self performBlock:^(id sender) { [self unregisterBackgroundDownload:connection]; } afterDelay:1.0];
    
    [TESTFLIGHT passCheckpoint:@"completed MBTiles download"];
}

@end