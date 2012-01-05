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
static NSString *const DSMapBoxDownloadCompleteNotification = @"DSMapBoxDownloadCompleteNotification";

@interface DSMapBoxDownloadManager : NSObject
{
}

@property (nonatomic, readonly, retain) NSMutableArray *downloads;

+ (id)sharedManager;

- (void)resumeDownloads;
- (void)pauseDownload:(ASIHTTPRequest *)download;
- (void)resumeDownload:(ASIHTTPRequest *)download;
- (void)cancelDownload:(ASIHTTPRequest *)download;

@end