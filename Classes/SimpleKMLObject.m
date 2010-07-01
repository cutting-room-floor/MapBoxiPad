//
//  SimpleKMLObject.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLObject.h"

@implementation SimpleKMLObject

@synthesize objectID;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super init];
    
    if (self != nil)
    {
        source = [[NSString stringWithString:[node XMLString]] retain];
        
        objectID = [[[[((CXMLElement *)node) attributeForName:@"id"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
    }
    
#pragma mark TODO: assert that abstract classes aren't being instantiated
    
    return self;
}

- (void)dealloc
{
    [source release];
    [objectID release];
    
    [super dealloc];
}

@end