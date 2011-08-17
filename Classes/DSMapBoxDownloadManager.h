//
//  DSMapBoxDownloadManager.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASIHTTPRequest.h"

@class ASINetworkQueue;

static NSString *const DSMapBoxDownloadQueueNotification    = @"DSMapBoxDownloadQueueNotification";
static NSString *const DSMapBoxDownloadProgressNotification = @"DSMapBoxDownloadProgressNotification";

@interface DSMapBoxDownloadManager : NSObject
{
    ASINetworkQueue *activeDownloadQueue;
    NSMutableArray *downloads;
    NSMutableArray *activeDownloads;
}

@property (nonatomic, readonly, retain) NSArray *downloads;
@property (nonatomic, readonly, assign) NSInteger activeDownloadCount;

+ (id)sharedManager;

- (void)pauseDownload:(ASIHTTPRequest *)download;
- (void)resumeDownload:(ASIHTTPRequest *)download;
- (BOOL)downloadIsActive:(ASIHTTPRequest *)download;

@end