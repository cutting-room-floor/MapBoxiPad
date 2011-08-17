//
//  DSMapBoxDownloadManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadManager.h"

#import "MapBoxConstants.h"

#import "ASINetworkQueue.h"

#import "UIApplication_Additions.h"

@interface DSMapBoxDownloadManager (DSMapBoxDownloadManagerPrivate)

- (NSArray *)pendingDownloads;

@end

#pragma mark -

@implementation DSMapBoxDownloadManager

static DSMapBoxDownloadManager *sharedManager;

+ (DSMapBoxDownloadManager *)sharedManager
{
    @synchronized(@"DSMapBoxDownloadManager")
    {
        if ( ! sharedManager)
            sharedManager = [[self alloc] init];
    }
    
    return sharedManager;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        downloads = [[NSMutableArray array] retain];
        activeDownloads = [[NSMutableArray array] retain];
        
        NSString *downloadPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDownloadsFolderName];

        BOOL isDir;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDir] || ! isDir)
        {
            [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath 
                                      withIntermediateDirectories:NO 
                                                       attributes:nil
                                                            error:NULL];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [activeDownloadQueue release];
    [downloads release];
    [activeDownloads release];
    
    [super dealloc];
}

#pragma mark -

- (NSArray *)downloads
{
    return [NSArray arrayWithArray:downloads];
}

- (void)setDownloads:(NSArray *)inDownloads
{
    [downloads setArray:inDownloads];
}

- (NSInteger)activeDownloadCount
{
    return [activeDownloads count];
}

#pragma mark -

- (NSArray *)pendingDownloads
{
    NSString *downloadsPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDownloadsFolderName];
    
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:downloadsPath error:NULL];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    for (NSString *path in paths)
        if ([[path pathExtension] isEqualToString:@"plist"])
            [fullPaths addObject:[NSString stringWithFormat:@"%@/%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDownloadsFolderName, path]];
    
    return [NSArray arrayWithArray:fullPaths];
}

- (void)resumeDownloads
{
    if ( ! activeDownloadQueue)
    {
        activeDownloadQueue = [[ASINetworkQueue queue] retain];
        
        activeDownloadQueue.delegate                 = self;
        activeDownloadQueue.downloadProgressDelegate = self;
        
        activeDownloadQueue.requestDidFinishSelector = @selector(requestFinished:);
        activeDownloadQueue.requestDidFailSelector   = @selector(requestFailed:);
        activeDownloadQueue.queueDidFinishSelector   = @selector(queueFinished:);

        activeDownloadQueue.shouldCancelAllRequestsOnFailure = NO;
        activeDownloadQueue.showAccurateProgress             = YES;

        [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:YES];
    }
    
    for (NSString *download in [self pendingDownloads])
    {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:download];
        
        NSURL *downloadURL = [NSURL URLWithString:[info objectForKey:@"URL"]];        
        
        NSMutableArray *allActiveURLs = [NSMutableArray arrayWithArray:[[activeDownloadQueue operations] valueForKeyPath:@"url"]];
        
        [allActiveURLs addObjectsFromArray:[[activeDownloadQueue operations] valueForKeyPath:@"originalURL"]];
        
        if ( ! [allActiveURLs containsObject:downloadURL])
        {
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:downloadURL];
                    
            request.downloadDestinationPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], [downloadURL lastPathComponent]];

            request.shouldContinueWhenAppEntersBackground = YES;
            request.allowResumeForFileDownloads           = YES;
            
            [activeDownloadQueue addOperation:request];
            
            [downloads addObject:request];

            [activeDownloads addObject:request];
        }
    }
    
    if ([activeDownloadQueue operationCount])
    {
        [activeDownloadQueue go];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:YES]];
    }
}

#pragma mark -

- (void)pauseDownload:(ASIHTTPRequest *)download
{
    // swap download with copy to be started up again later
    //
    // per http://groups.google.com/group/asihttprequest/browse_thread/thread/a6f89a9fb0587874/
    //
    NSLog(@"pausing %@ (%@)", download, [(download.originalURL ? download.originalURL : download.url) lastPathComponent]);

    [download clearDelegatesAndCancel];

    ASIHTTPRequest *newDownload = [[download copy] autorelease];
    
    [downloads replaceObjectAtIndex:[downloads indexOfObject:download] withObject:newDownload];
    
    [activeDownloads removeObject:download];
}

- (void)resumeDownload:(ASIHTTPRequest *)download
{
    NSLog(@"resuming %@ (%@)", download, [(download.originalURL ? download.originalURL : download.url) lastPathComponent]);
   
    [download startAsynchronous];
    
    [activeDownloads addObject:download];
}

- (void)cancelDownload:(ASIHTTPRequest *)download
{
    NSLog(@"cancelling %@ (%@)", download, [(download.originalURL ? download.originalURL : download.url) lastPathComponent]);
    
    [download clearDelegatesAndCancel];
    
    [download removeTemporaryDownloadFile];
    
    [activeDownloads removeObject:download];
    
    [downloads removeObject:download];
}

- (BOOL)downloadIsActive:(ASIHTTPRequest *)download
{
    return [activeDownloads containsObject:download];
}

#pragma mark -

- (void)setProgress:(float)progress
{
    NSLog(@"%f of %qu", progress, activeDownloadQueue.totalBytesToDownload);
    
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadProgressNotification object:[NSNumber numberWithFloat:progress]];
}

#pragma mark -

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"finished: %@", request);
    
    [activeDownloads removeObject:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"failed: %@", request.error);
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
    NSLog(@"queue finished: %@", queue);
    
    [queue release];
    queue = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDownloadQueueNotification object:[NSNumber numberWithBool:NO]];
}

@end