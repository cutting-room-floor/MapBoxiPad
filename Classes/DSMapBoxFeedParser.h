//
//  DSMapBoxFeedParser.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSMapBoxFeedParser : NSObject
{
}

+ (Class)parserClassForFeed:(NSString *)feed;
+ (NSArray *)itemsForFeed:(NSString *)feed;

@end