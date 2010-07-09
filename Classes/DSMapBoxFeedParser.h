//
//  DSMapBoxFeedParser.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSMapBoxFeedParser : NSObject
{
}

+ (Class)parserClassForFeed:(NSString *)feed;
+ (NSArray *)itemsForFeed:(NSString *)feed;

@end