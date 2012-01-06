//
//  DSMapBoxDownloadManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadManager.h"

#import "MapBoxConstants.h"

#import "UIApplication_Additions.h"

#import "TestFlight.h"

@interface DSMapBoxDownloadManager ()

@property (nonatomic, strong) NSMutableArray *downloads;
@property (nonatomic, strong) NSMutableArray *pausedDownloads;
@property (nonatomic, strong) NSMutableArray *progresses;

- (NSString *)downloadsPath;
- (NSString *)identifierForDownload:(NSURLConnection *)download;
- (NSArray *)pendingDownloads;

@end

#pragma mark -

@implementation DSMapBoxDownloadManager

@synthesize downloads;
@synthesize pausedDownloads;
@synthesize progresses;

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
        pausedDownloads = [NSMutableArray array];
        progresses      = [NSMutableArray array];
        
        BOOL isDir;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:[self downloadsPath] isDirectory:&isDir] || ! isDir)
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self downloadsPath] error:NULL];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:[self downloadsPath]
                                      withIntermediateDirectories:NO 
                                                       attributes:nil
                                                            error:NULL];
        }
    }
    
    return self;
}

#pragma mark -

- (NSString *)downloadsPath
{
    return [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDownloadsFolderName];
}

- (NSString *)identifierForDownload:(NSURLConnection *)download
{
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self downloadsPath] error:NULL];
    
    for (NSString *path in paths)
        if ([[path pathExtension] isEqualToString:@"plist"])
            if ([[[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [self downloadsPath], path]] objectForKey:@"URL"] isEqualToString:[download.originalRequest.URL absoluteString]])
                return [[path lastPathComponent] stringByReplacingOccurrencesOfString:@".plist" withString:@""];

    return nil;
}

- (NSArray *)pendingDownloads
{
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self downloadsPath] error:NULL];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    for (NSString *path in paths)
        if ([[path pathExtension] isEqualToString:@"plist"])
            [fullPaths addObject:[NSString stringWithFormat:@"%@/%@", [self downloadsPath], path]];
    
    return [NSArray arrayWithArray:fullPaths];
}

#pragma mark -

- (void)resumeDownloads
{
    for (NSString *downloadStubFile in [self pendingDownloads])
    {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:downloadStubFile];
        
        NSURL *downloadURL = [NSURL URLWithString:[info objectForKey:@"URL"]];        
        
        if ( ! [[self.downloads valueForKeyPath:@"originalRequest.URL"] containsObject:downloadURL])
        {
            
            
            
            
            
            
            
            NSURLConnection *download = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:downloadURL] 
                                                                        delegate:self
                                                                startImmediately:NO];
                    
            
            

            // add resume header
            
            
            
            
//			backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//				// Synchronize the cleanup call on the main thread in case
//				// the task actually finishes at around the same time.
//				dispatch_async(dispatch_get_main_queue(), ^{
//					if (backgroundTask != UIBackgroundTaskInvalid)
//					{
//						[[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
//						backgroundTask = UIBackgroundTaskInvalid;
//						[self cancel];
//					}
//				});
//			}];

            
            
            
            [self.downloads  addObject:download];
            [self.progresses addObject:[NSNumber numberWithFloat:0.0]];
            
            [download scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
            
            [download start];
        }
    }
    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:([[self downloads] count] ? YES : NO)]];
    
    
    
    
}

#pragma mark -

- (void)pauseDownload:(NSURLConnection *)download
{
    NSLog(@"pausing %@", download.originalRequest.URL);
    
    [self.pausedDownloads addObject:download];

    [download cancel];
    
    [TestFlight passCheckpoint:@"paused MBTiles download"];
}

- (void)resumeDownload:(NSURLConnection *)download
{
    NSLog(@"resuming %@", download.originalRequest.URL);
   
    [self.pausedDownloads removeObject:download];
    
    NSURLConnection *replacementDownload = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:download.originalRequest.URL] 
                                                                           delegate:self
                                                                   startImmediately:NO];
    
    [self.downloads replaceObjectAtIndex:[self.downloads indexOfObject:download] withObject:replacementDownload];
    
    [replacementDownload scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    
    [replacementDownload start];
    
    [download cancel];
    
    [TestFlight passCheckpoint:@"resumed MBTiles download"];
}

- (void)cancelDownload:(NSURLConnection *)download
{
    NSLog(@"cancelling %@", download.originalRequest.URL);
    
    [download cancel];

    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:download]];
    [self.downloads  removeObject:download];

    NSString *identifier = [self identifierForDownload:download];
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.%@", [self downloadsPath], identifier, kPartialDownloadExtension] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@.plist", [self downloadsPath], identifier] error:NULL];
    
    [TestFlight passCheckpoint:@"cancelled MBTiles download"];
}

- (BOOL)downloadIsPaused:(NSURLConnection *)download
{
    NSLog(@"checking pause status for %@", download.originalRequest.URL);
    
    return [self.pausedDownloads containsObject:download];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ( ! [self.downloads containsObject:connection])
        return;
    
    NSHTTPURLResponse *webResponse = (NSHTTPURLResponse *)response;
    
    NSLog(@"connected %@ with HTTP %i", connection.originalRequest.URL, webResponse.statusCode);
    
    
    
    NSInteger length = [[[webResponse allHeaderFields] objectForKey:@"Content-Length"] integerValue];
    
    NSString *downloadStubFile = [NSString stringWithFormat:@"%@/%@.plist", [self downloadsPath], [self identifierForDownload:connection]];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:downloadStubFile];
    
    [info setObject:[NSNumber numberWithInteger:length] forKey:@"Size"];
    
    [info writeToFile:downloadStubFile atomically:YES];
    
    
    
    // check for resume
    
    
    NSString *downloadPath = [NSString stringWithFormat:@"%@/%@.%@", [self downloadsPath], [self identifierForDownload:connection], kPartialDownloadExtension];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL]; // FIXME resume
    
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:downloadPath])
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:[NSData data] attributes:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ( ! [self.downloads containsObject:connection])
        return;

    NSLog(@"failed %@: %@", connection.originalRequest.URL, error);

    // don't remove the stub file so resumes can possibly pick it up
    
    [TestFlight passCheckpoint:@"failed MBTiles download"];
    
    [self pauseDownload:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ( ! [self.downloads containsObject:connection])
        return;

//    NSLog(@"received %i bytes for %@", [data length], connection.originalRequest.URL);
    
    // append to disk
    
    NSString *identifier = [self identifierForDownload:connection];
    
    
    NSString *downloadPath = [NSString stringWithFormat:@"%@/%@.%@", [self downloadsPath], identifier, kPartialDownloadExtension];

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:downloadPath];
    
    [handle seekToEndOfFile];
    
    
    unsigned long long totalDownloaded = [handle offsetInFile] + [data length];

    
    NSInteger totalSize = [[[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist", [self downloadsPath], identifier]] objectForKey:@"Size"] integerValue];
    
    CGFloat thisProgress = (CGFloat)totalDownloaded / (CGFloat)totalSize;
    
    [self.progresses replaceObjectAtIndex:[self.downloads indexOfObject:connection] withObject:[NSNumber numberWithFloat:thisProgress]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification 
                                                        object:connection
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:thisProgress] 
                                                                                           forKey:DSMapBoxDownloadProgressKey]];

    
    
    
    
    
    
    [handle writeData:data];
    
    [handle closeFile];
    
    
    
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
    if ( ! [self.downloads containsObject:connection])
        return;

    NSString *downloadedFile = [NSString stringWithFormat:@"%@/%@.%@", [self downloadsPath], [self identifierForDownload:connection], kPartialDownloadExtension];
    
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:downloadedFile error:NULL];
    
    NSLog(@"finished %@ to %@ at size %@", connection.originalRequest.URL, downloadedFile, [info objectForKey:NSFileSize]);

    for (NSString *path in [self pendingDownloads])
        if ([[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"URL"] isEqualToString:[connection.originalRequest.URL absoluteString]])
            [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    [self.progresses removeObjectAtIndex:[self.downloads indexOfObject:connection]];
    [self.downloads  removeObject:connection];
    
    [TestFlight passCheckpoint:@"completed MBTiles download"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadCompleteNotification object:connection];
    
    
    
    
    
    // check queue
    
    if ([self.downloads count] == 0)
    {
        NSLog(@"queue finished");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:NO]];
    }
    
    
}

@end