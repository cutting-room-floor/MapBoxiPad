//
//  SimpleKMLBalloonStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLBalloonStyle.h"

@implementation SimpleKMLBalloonStyle

@synthesize backgroundColor;
@synthesize textColor;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        backgroundColor = [[UIColor whiteColor] retain];
        textColor       = [[UIColor blackColor] retain];
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"bgColor"])
            {
                NSString *colorString = [child stringValue];
             
                [backgroundColor release];
                backgroundColor = [[SimpleKML colorForString:colorString] retain];
            }
            else if ([[child name] isEqualToString:@"textColor"])
            {
                NSString *colorString = [child stringValue];
                
                [textColor release];
                textColor = [[SimpleKML colorForString:colorString] retain];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [backgroundColor release];
    [textColor release];
    
    [super dealloc];
}

@end