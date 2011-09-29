//
//  DSMapBoxFeedParserAtom.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxFeedParser.h"

@interface DSMapBoxFeedParserAtom : DSMapBoxFeedParser
{
}

+ (NSArray *)itemsForFeed:(NSString *)feed;

@end