//
//  SimpleKMLPolyStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/2/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLPolyStyle.h"

@implementation SimpleKMLPolyStyle

@synthesize fill;
@synthesize outline;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        fill = NO;
        outline = NO;
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"fill"])
                fill = [[child stringValue] boolValue];

            else if ([[child name] isEqualToString:@"outline"])
                outline = [[child stringValue] boolValue];
        }
    }
    
    return self;
}

@end