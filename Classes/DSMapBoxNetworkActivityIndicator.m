//
//  DSMapBoxNetworkActivityIndicator.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/5/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "DSMapBoxNetworkActivityIndicator.h"

@interface DSMapBoxNetworkActivityIndicator ()

@property (nonatomic, strong) NSMutableSet *jobs;

+ (DSMapBoxNetworkActivityIndicator *)sharedInstance;

@end

#pragma mark -

@implementation DSMapBoxNetworkActivityIndicator

@synthesize jobs;

+ (DSMapBoxNetworkActivityIndicator *)sharedInstance
{
    static dispatch_once_t token;
    static DSMapBoxNetworkActivityIndicator *sharedInstance = nil;
    
    dispatch_once(&token, ^{ sharedInstance = [[self alloc] init]; });

    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
        jobs = [NSMutableSet set];
    
    return self;
}

#pragma mark -

+ (void)addJob:(id)item
{
    DSMapBoxNetworkActivityIndicator *sharedInstance = [DSMapBoxNetworkActivityIndicator sharedInstance];
    
    [sharedInstance.jobs addObject:item];
    
    if ([sharedInstance.jobs count] > 0)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

+ (void)removeJob:(id)item
{
    DSMapBoxNetworkActivityIndicator *sharedInstance = [DSMapBoxNetworkActivityIndicator sharedInstance];

    [sharedInstance.jobs removeObject:item];
    
    if ([sharedInstance.jobs count] == 0)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end