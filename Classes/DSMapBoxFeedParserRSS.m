//
//  DSMapBoxFeedParserRSS.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxFeedParserRSS.h"

#import "TouchXML.h"

@implementation DSMapBoxFeedParserRSS

+ (NSArray *)itemsForFeed:(NSString *)feed
{
    NSMutableArray *parsedItems = [NSMutableArray array];
    
    NSError *error = nil;

    CXMLDocument *doc = [[[CXMLDocument alloc] initWithXMLString:feed options:0 error:&error] autorelease];

    if ( ! error)
    {
        NSArray *items = [doc nodesForXPath:@"/rss/channel/item[georss:point!='0 0']" 
                          namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.georss.org/georss" forKey:@"georss"] 
                                      error:NULL];
        
        for (CXMLElement *item in items)
        {
            NSString *title       = [[[item elementsForName:@"title"]       objectAtIndex:0] stringValue];
            NSString *description = [[[item elementsForName:@"description"] objectAtIndex:0] stringValue];
            NSString *link        = [[[item elementsForName:@"link"]        objectAtIndex:0] stringValue];
            NSString *date        = [[[item elementsForName:@"pubDate"]     objectAtIndex:0] stringValue];
            NSString *point       = [[[item elementsForName:@"point"]       objectAtIndex:0] stringValue];
            
            CGFloat latitude  = [[[point componentsSeparatedByString:@" "] objectAtIndex:0] floatValue];
            CGFloat longitude = [[[point componentsSeparatedByString:@" "] objectAtIndex:1] floatValue];
            
            [parsedItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:title,                                @"title",
                                                                              description,                          @"description", 
                                                                              link,                                 @"link", 
                                                                              date,                                 @"date",
                                                                              [NSNumber numberWithFloat:latitude],  @"latitude",
                                                                              [NSNumber numberWithFloat:longitude], @"longitude",
                                                                              nil]];
        }
    }
    
    return [NSArray arrayWithArray:parsedItems];
}

@end