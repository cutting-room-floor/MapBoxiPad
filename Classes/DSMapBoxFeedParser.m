//
//  DSMapBoxFeedParser.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxFeedParser.h"

#import "DSMapBoxFeedParserRSS.h"
#import "DSMapBoxFeedParserAtom.h"

#import "TouchXML.h"

@implementation DSMapBoxFeedParser

+ (Class)parserClassForFeed:(NSString *)feed
{
    NSError *error = nil;
    
    CXMLDocument *doc = [[[CXMLDocument alloc] initWithXMLString:feed options:0 error:&error] autorelease];
    
    if (error)
        return nil;
    
    CXMLNode *rss = [doc nodeForXPath:@"/rss" error:NULL];
    
    if (rss)
        return [DSMapBoxFeedParserRSS class];
    
    CXMLNode *atom = [[doc nodesForXPath:@"/atom:feed" 
                       namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.w3.org/2005/Atom" forKey:@"atom"]
                                   error:&error] lastObject];
    
    if (atom)
        return [DSMapBoxFeedParserAtom class];
    
    return nil;
}

+ (NSArray *)itemsForFeed:(NSString *)feed
{
    Class parserClass = [self parserClassForFeed:feed];
    
    if (parserClass)
        return [parserClass itemsForFeed:feed];
    
    return [NSArray array];
}

@end