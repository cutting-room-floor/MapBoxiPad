//
//  DSMapBoxTileStreamCommon.m
//  MapBoxiPad
//
//  Created by Justin Miller on 11/11/11.
//  Copyright (c) 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxTileStreamCommon.h"

@implementation DSMapBoxTileStreamCommon

+ (NSString *)serverHostnamePrefix
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serverHostnamePrefix;
    
    if ([defaults stringForKey:@"alternateHostingServer"] && [[defaults stringForKey:@"alternateHostingServer"] length])
        serverHostnamePrefix = [defaults stringForKey:@"alternateHostingServer"];
    
    else
        serverHostnamePrefix = kTileStreamHostingPrefix;
    
    if ( ! [serverHostnamePrefix hasPrefix:@"http://"] && ! [serverHostnamePrefix hasPrefix:@"https://"])
        serverHostnamePrefix = [@"http://" stringByAppendingString:serverHostnamePrefix];
    
    return serverHostnamePrefix;
}

@end