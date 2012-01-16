//
//  DSMapBoxDownloadManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadManager.h"

#import "DSMapBoxNotificationCenter.h"

#import "Reachability.h"

@interface NSURLConnection (DSMapBoxDownloadManagerPrivate)

- (void)setIsPaused:(BOOL)flag;
- (void)setIsIndeterminate:(BOOL)flag;
- (void)setIdentifier:(NSString *)newIdentifier;
- (NSString *)identifier;
- (NSString *)downloadPath;
- (void)setFileHandle:(NSFileHandle *)newFileHandle;
- (NSFileHandle *)fileHandle;

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
        
        downloadsPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDownloadsFolderName];
        
        // create downloads path if needed
        //
        BOOL isDir;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:downloadsPath isDirectory:&isDir] || ! isDir)
        {
            [[NSFileManager defaultManager] removeItemAtPath:downloadsPath error:NULL];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:downloadsPath
                                      withIntermediateDirectories:NO 
                                                       attributes:nil
                                                            error:NULL];
        }
        
        // watch for net changes
        //
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
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
    if ( ! download.identifier)
    {    
        NSString *path = [self.pendingDownloads match:^(id obj)
                         {
                             return [[[NSDictionary dictionaryWithContentsOfFile:obj] objectForKey:@"URL"] isEqualToString:[download.originalRequest.URL absoluteString]];
                         }];
        
        download.identifier = [[path lastPathComponent] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
    }
    
    return download.identifier;
}

- (void)downloadURL:(NSURL *)downloadURL resumingDownload:(NSURLConnection *)pausedDownload
{
    // create the new request & download
    //
    DSMapBoxURLRequest *request = [DSMapBoxURLRequest requestWithURL:downloadURL];
    NSURLConnection *download   = [NSURLConnection connectionWithRequest:request];

    // figure out if we'll try to resume a previous download
    //
    NSString *existingFilePath = [NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, [self identifierForDownload:download], kPartialDownloadExtension];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:existingFilePath])
    {
        NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:existingFilePath error:NULL];
        
        if ([info objectForKey:NSFileSize])
        {
            // replace the request & download with resuming versions
            //
            [request setValue:[NSString stringWithFormat:@"bytes=%i-", [[info objectForKey:NSFileSize] unsignedIntegerValue]] forHTTPHeaderField:@"Range"];
    
            download = [NSURLConnection connectionWithRequest:request];
        }
    }
    
    download.delegate = self;
    
    // update internal tracking for download
    //
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

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWiFi)
    {
        // upgraded to wifi - resume downloads, which will notify individually
        //
        [self resumeDownloads];
    }
    else if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        if ([self.downloads count])
        {
            [[DSMapBoxNotificationCenter sharedInstance] notifyWithMessage:@"Automatic downloads paused on cellular connection"];
            
            // downgraded to cellular - pause all downloads
            //
            for (NSURLConnection *download in self.downloads)
                if ( ! download.isPaused)
                    [self pauseDownload:download];
        }
    }
}

#pragma mark -

- (void)resumeDownloads
{
    // grab new URLs & find stub files with duplicate URLs
    //
    NSMutableArray *duplicates = [NSMutableArray array];
    
    for (NSString *downloadStubFile in self.pendingDownloads)
    {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:downloadStubFile];
        
        NSURL *downloadURL = [NSURL URLWithString:[info objectForKey:@"URL"]];        
        
        if ([[self.downloads valueForKeyPath:@"originalRequest.URL"] containsObject:downloadURL])
            [duplicates addObject:downloadStubFile];
        else
            [self downloadURL:downloadURL resumingDownload:nil];
    }
    
    // delete duplicate stub files
    //
    for (NSString *dupe in duplicates)
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, dupe] error:NULL];
    
    // catch any paused downloads & resume them
    //
    for (NSURLConnection *download in self.downloads)
        if (download.isPaused)
            [self resumeDownload:download];
    
    // ensure queue watchers update
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification 
                                                        object:[NSNumber numberWithBool:([self.downloads count] ? YES : NO)]];
}

#pragma mark -

- (void)pauseDownload:(NSURLConnection *)download
{
    NSLog(@"pausing %@", download.originalRequest.URL);
    
    download.isPaused = YES;

    [download cancel];
    
    [download.fileHandle closeFile];
    
    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundTaskForDownload:download];

    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification 
                                                        object:[NSNumber numberWithBool:([self.downloads count] ? YES : NO)]];

    [TESTFLIGHT passCheckpoint:@"paused MBTiles download"];
}

- (void)resumeDownload:(NSURLConnection *)download
{
    NSLog(@"resuming %@", download.originalRequest.URL);
   
    download.isPaused = NO;
    
    [self downloadURL:download.originalRequest.URL resumingDownload:download];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:YES]];
    
    [TESTFLIGHT passCheckpoint:@"resumed MBTiles download"];
}

- (void)cancelDownload:(NSURLConnection *)download
{
    NSLog(@"cancelling %@", download.originalRequest.URL);
    
    [download cancel];

    [download.fileHandle closeFile];

    [DSMapBoxNetworkActivityIndicator removeJob:download];
    
    [self unregisterBackgroundTaskForDownload:download];
    
    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:download]];
    [self.downloads  removeObject:download];

    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.%@", self.downloadsPath, [self identifierForDownload:download], kPartialDownloadExtension] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, [self identifierForDownload:download]] error:NULL];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification 
                                                        object:[NSNumber numberWithBool:([self.downloads count] ? YES : NO)]];
    
    [TESTFLIGHT passCheckpoint:@"cancelled MBTiles download"];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *webResponse = (NSHTTPURLResponse *)response;
    
    NSLog(@"connected %@ with HTTP %i", connection.originalRequest.URL, webResponse.statusCode);
    
    // error out if not available
    //
    if ([webResponse statusCode] >= 400)
        return [self connection:connection didFailWithError:nil];

    // notify of start
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadBeganNotification object:connection];
    
    // determine if resuming partial download
    //
    NSString *stubFile = [NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, [self identifierForDownload:connection]];

    NSMutableDictionary *stubInfo = [NSMutableDictionary dictionaryWithContentsOfFile:stubFile];

    BOOL resuming = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:connection.downloadPath]) // we have a partial download
    {
        if ([[[webResponse allHeaderFields] objectForKey:@"Accept-Ranges"] isEqualToString:@"bytes"]) // server allows resumes
        {
            if ([[webResponse allHeaderFields] objectForKey:@"Content-Length"]) // we're told how much we're getting
            {
                NSDictionary *downloadInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:connection.downloadPath error:NULL];
                
                NSUInteger expectedSize   = [[stubInfo objectForKey:@"Size"] unsignedIntegerValue];
                NSUInteger downloadedSize = [[downloadInfo objectForKey:NSFileSize] unsignedIntegerValue];
                NSUInteger reportedSize   = [[[webResponse allHeaderFields] objectForKey:@"Content-Length"] intValue];
                
                if (expectedSize - downloadedSize == reportedSize) // ranges match up
                    resuming = YES;
            }
        }
    }
    
    // determine if we need have the full size recorded yet
    //
    if ( ! [stubInfo objectForKey:@"Size"] && [[webResponse allHeaderFields] objectForKey:@"Content-Length"])
    {
        [stubInfo setObject:[NSNumber numberWithInteger:[[[webResponse allHeaderFields] objectForKey:@"Content-Length"] integerValue]] forKey:@"Size"];
        [stubInfo writeToFile:stubFile atomically:YES];
    }
    
    // determine if known size
    //
    if ( ! [[webResponse allHeaderFields] objectForKey:@"Content-Length"])
        connection.isIndeterminate = YES;

    // create file if needed
    //
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:connection.downloadPath])
        [[NSFileManager defaultManager] createFileAtPath:connection.downloadPath contents:nil attributes:nil];
    
    // open file handle
    //
    connection.fileHandle = [NSFileHandle fileHandleForWritingAtPath:connection.downloadPath];
    
    // zero file if not resuming
    //
    if ( ! resuming)
        [connection.fileHandle truncateFileAtOffset:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"failed %@: %@", connection.originalRequest.URL, error);

    [DSMapBoxNetworkActivityIndicator removeJob:connection];

    [connection.fileHandle closeFile];
    
    // pause, leaving partial file to possibly resume
    //
    [self pauseDownload:connection];

    [TESTFLIGHT passCheckpoint:@"failed MBTiles download"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append data to file
    //
    [connection.fileHandle seekToEndOfFile];
    
    // figure out how much data this gives us
    //
    unsigned long long totalDownloaded = [connection.fileHandle offsetInFile] + [data length];
    
    // append data & close file
    //
    [connection.fileHandle writeData:data];
    
    // update progress tracking if possible
    //
    NSUInteger totalSize = 0.0;
    CGFloat thisProgress = 0.0;
    
    if ( ! connection.isIndeterminate)
    {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist", self.downloadsPath, [self identifierForDownload:connection]]];

        totalSize    = [[info objectForKey:@"Size"] integerValue];
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

    [connection.fileHandle closeFile];

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
    
    // wait a sec for UI to update, then invalidate background job
    //
    [self performBlock:^(id sender)
    {
        // remove background job tracking
        //
        [self unregisterBackgroundTaskForDownload:connection];

        // post queue update
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification 
                                                            object:[NSNumber numberWithBool:([self.downloads count] ? YES : NO)]];
    }
    afterDelay:1.0];
    
    [TESTFLIGHT passCheckpoint:@"completed MBTiles download"];
}

@end

#pragma mark -

@implementation NSURLConnection (DSMapBoxDownloadManager)

static const char *DSMapBoxDownloadManagerDownloadIsPaused        = "DSMapBoxDownloadManagerDownloadIsPaused";
static const char *DSMapBoxDownloadManagerDownloadIsIndeterminate = "DSMapBoxDownloadManagerDownloadIsIndeterminate";
static const char *DSMapBoxDownloadManagerDownloadIdentifier      = "DSMapBoxDownloadManagerDownloadIdentifier";
static const char *DSMapBoxDownloadManagerDownloadFileHandle      = "DSMapBoxDownloadManagerDownloadFileHandle";

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

- (void)setIdentifier:(NSString *)newIdentifier
{
    [self associateValue:newIdentifier withKey:DSMapBoxDownloadManagerDownloadIdentifier];
}

- (NSString *)identifier
{
    return [self associatedValueForKey:DSMapBoxDownloadManagerDownloadIdentifier];
}

- (NSString *)downloadPath
{
    return [NSString stringWithFormat:@"%@/%@.%@", [DSMapBoxDownloadManager sharedManager].downloadsPath, self.identifier, kPartialDownloadExtension];
}

- (void)setFileHandle:(NSFileHandle *)newFileHandle
{
    [self associateValue:newFileHandle withKey:DSMapBoxDownloadManagerDownloadFileHandle];
}

- (NSFileHandle *)fileHandle
{
    return [self associatedValueForKey:DSMapBoxDownloadManagerDownloadFileHandle];
}

@end