//
//  DSMapBoxFeedParserAtom.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxFeedParserAtom.h"

#import "TouchXML.h"

@implementation DSMapBoxFeedParserAtom

+ (NSArray *)itemsForFeed:(NSString *)feed
{
    NSMutableArray *parsedItems = [NSMutableArray array];

    NSError *error = nil;
    
    CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:feed options:0 error:&error];
    
    if ( ! error)
    {
        NSDictionary *namespaces = [NSDictionary dictionaryWithObjectsAndKeys:@"http://www.w3.org/2005/Atom",  @"atom",
                                                                              @"http://www.georss.org/georss", @"georss",
                                                                              nil];
        
        NSArray *items = [doc nodesForXPath:@"/atom:feed/atom:entry[georss:point!='0 0']" 
                          namespaceMappings:namespaces 
                                      error:NULL];
        
        NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        for (CXMLElement *item in items)
        {
            NSString *title       = @"Untitled";
            NSString *description = @"(no description)";
            NSString *link        = @"";
            NSString *date        = @"(no date)";
            NSString *point       = @"0 0";
            
            if ([[item elementsForName:@"title"] count])
                title = [[[item elementsForName:@"title"] objectAtIndex:0] stringValue];
            
            if ([[item elementsForName:@"content"] count])
                description = [[[item elementsForName:@"content"] objectAtIndex:0] stringValue];

            else if ([[item elementsForName:@"summary"] count])
                description = [[[item elementsForName:@"summary"] objectAtIndex:0] stringValue];

            if ([[item elementsForName:@"published"] count])
                date = [[[item elementsForName:@"published"] objectAtIndex:0] stringValue];
            
            else if ([[item elementsForName:@"updated"] count])
                date = [[[item elementsForName:@"updated"] objectAtIndex:0] stringValue];
            
            if ([[item elementsForName:@"point"] count])
                point = [[[[item elementsForName:@"point"] objectAtIndex:0] stringValue] stringByTrimmingCharactersInSet:trimSet];
            
            CXMLElement *linkElement = [[item nodesForXPath:@"atom:link[@rel='alternate']" 
                                          namespaceMappings:namespaces 
                                                      error:NULL] lastObject];
            
            if (linkElement)
                link = [[linkElement attributeForName:@"href"] stringValue];
            
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