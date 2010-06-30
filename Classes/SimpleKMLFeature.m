//
//  SimpleKMLFeature.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLFeature.h"

@implementation SimpleKMLFeature

@synthesize name;
@synthesize featureDescription;
@synthesize style;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"name"])
                name = [[[child stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
            
            else if ([[child name] isEqualToString:@"description"])
                featureDescription = [[[child stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
            
#pragma mark TODO: parse into style reference
            else if ([[child name] isEqualToString:@"styleUrl"])
                style = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    [featureDescription release];
    [style release];
    
    [super dealloc];
}

@end