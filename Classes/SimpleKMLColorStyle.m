//
//  SimpleKMLColorStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLColorStyle.h"

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLColorStyle

@synthesize color;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        color = nil;
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"color"])
            {
                NSString *colorString = [child stringValue];
                
                color = [[SimpleKML colorForString:colorString] retain];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [color release];
    
    [super dealloc];
}

@end