//
//  SimpleKMLPlacemark.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLPlacemark.h"
#import "SimpleKMLGeometry.h"

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLPlacemark

@synthesize geometry;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        geometry = nil;
        
        for (CXMLNode *child in [node children])
        {
            // there should only be zero or one geometries
            //
            if ( ! geometry)
            {
                Class geometryClass = NSClassFromString([NSString stringWithFormat:@"SimpleKML%@", [child name]]);
                
                if (geometryClass)
                {
                    id thisGeometry = [[[geometryClass alloc] initWithXMLNode:child error:NULL] autorelease];
                    
                    if (thisGeometry && [thisGeometry isKindOfClass:[SimpleKMLGeometry class]])
                        geometry = thisGeometry;
                }
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [geometry release];
    
    [super dealloc];
}

@end