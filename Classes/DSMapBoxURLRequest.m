//
//  DSMapBoxURLRequest.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/9/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "DSMapBoxURLRequest.h"

@implementation DSMapBoxURLRequest

- (id)initWithURL:(NSURL *)theURL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    self = [super initWithURL:theURL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    
    if (self)
    {
        NSLog(@"got here");
        
        NSString *info = [NSString stringWithFormat:@"%@ for %@ %@.%@", 
                             [[NSProcessInfo processInfo] processName],
                             [UIDevice currentDevice].model,
                             [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                             [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""]];
        
        [self setValue:info forHTTPHeaderField:@"User-Agent"];
    }
    
    return self;
}

@end