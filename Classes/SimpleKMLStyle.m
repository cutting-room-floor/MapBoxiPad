//
//  SimpleKMLStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLStyle.h"
#import "SimpleKMLIconStyle.h"
#import "SimpleKMLLineStyle.h"

@implementation SimpleKMLStyle

@synthesize iconStyle;
@synthesize lineStyle;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        iconStyle = nil;
        lineStyle = nil;
        
        for (CXMLNode *child in [node children])
        {
            Class subStyleClass = NSClassFromString([NSString stringWithFormat:@"SimpleKML%@", [child name]]);
            
            if (subStyleClass)
            {
                id thisSubStyle = [[[subStyleClass alloc] initWithXMLNode:child error:NULL] autorelease];
                
                if (thisSubStyle && [thisSubStyle isKindOfClass:[SimpleKMLSubStyle class]])
                {
                    if ([thisSubStyle isKindOfClass:[SimpleKMLIconStyle class]])
                        iconStyle = [thisSubStyle retain];
                    
                    else if ([thisSubStyle isKindOfClass:[SimpleKMLLineStyle class]])
                        lineStyle = [thisSubStyle retain];
                }
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [iconStyle release];
    [lineStyle release];
    
    [super dealloc];
}

@end