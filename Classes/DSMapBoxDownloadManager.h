//
//  DSMapBoxDownloadManager.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

static NSString *const DSMapBoxDownloadQueueNotification    = @"DSMapBoxDownloadQueueNotification";
static NSString *const DSMapBoxDownloadProgressNotification = @"DSMapBoxDownloadProgressNotification";
static NSString *const DSMapBoxDownloadCompleteNotification = @"DSMapBoxDownloadCompleteNotification";
static NSString *const DSMapBoxDownloadProgressKey          = @"DSMapBoxDownloadProgressKey";

@interface DSMapBoxDownloadManager : NSObject <NSURLConnectionDelegate>

@property (nonatomic, readonly, strong) NSMutableArray *downloads;

+ (DSMapBoxDownloadManager *)sharedManager;

- (void)resumeDownloads;
- (void)pauseDownload:(NSURLConnection *)download;
- (void)resumeDownload:(NSURLConnection *)download;
- (void)cancelDownload:(NSURLConnection *)download;
- (BOOL)downloadIsPaused:(NSURLConnection *)download;

@end