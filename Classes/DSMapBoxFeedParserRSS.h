//
//  DSMapBoxFeedParserRSS.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxFeedParser.h"

@interface DSMapBoxFeedParserRSS : DSMapBoxFeedParser
{
}

+ (NSArray *)itemsForFeed:(NSString *)feed;

@end