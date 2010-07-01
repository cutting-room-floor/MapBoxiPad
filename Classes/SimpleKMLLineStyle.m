//
//  SimpleKMLLineStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLLineStyle.h"

#define kSimpleKMLLineStyleDefaultWidth 0.0f

@implementation SimpleKMLLineStyle

@synthesize width;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        width = kSimpleKMLLineStyleDefaultWidth;
        
        for (CXMLNode *child in [node children])
            if ([[child name] isEqualToString:@"width"])
                width = (CGFloat)[[child stringValue] floatValue];
    }
    
    return self;
}

@end