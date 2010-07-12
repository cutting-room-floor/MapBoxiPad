//
//  DSMapBoxFeedParserAtom.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxFeedParserAtom.h"

#import "TouchXML.h"

@implementation DSMapBoxFeedParserAtom

+ (NSArray *)itemsForFeed:(NSString *)feed
{
    NSMutableArray *parsedItems = [NSMutableArray array];

    NSError *error = nil;
    
    CXMLDocument *doc = [[[CXMLDocument alloc] initWithXMLString:feed options:0 error:&error] autorelease];
    
    if ( ! error)
    {
        NSDictionary *namespaces = [NSDictionary dictionaryWithObjectsAndKeys:@"http://www.w3.org/2005/Atom",  @"atom",
                                                                              @"http://www.georss.org/georss", @"georss",
                                                                              nil];
        
        NSArray *items = [doc nodesForXPath:@"/atom:feed/atom:entry[georss:point!='0 0']" 
                          namespaceMappings:namespaces 
                                      error:NULL];
        
        for (CXMLElement *item in items)
        {
            NSString *title       = [[[item elementsForName:@"title"]     objectAtIndex:0] stringValue];
            NSString *description = [[[item elementsForName:@"content"]   objectAtIndex:0] stringValue];
            NSString *date        = [[[item elementsForName:@"published"] objectAtIndex:0] stringValue];
            NSString *point       = [[[item elementsForName:@"point"]     objectAtIndex:0] stringValue];

            CXMLElement *linkElement = [[item nodesForXPath:@"atom:link[@rel='alternate']" 
                                          namespaceMappings:namespaces 
                                                      error:NULL] lastObject];
            
            NSString *link = [[linkElement attributeForName:@"href"] stringValue];
            
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