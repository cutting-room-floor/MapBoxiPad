//
//  SimpleKMLContainer.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLContainer.h"

@implementation SimpleKMLContainer

@synthesize features;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        NSMutableArray *featuresArray = [NSMutableArray array];
        
        for (CXMLNode *child in [node children])
        {
            Class featureClass = NSClassFromString([NSString stringWithFormat:@"SimpleKML%@", [child name]]);
            
            if (featureClass)
            {
                NSError *parseError = nil;
                
                id feature = [[[featureClass alloc] initWithXMLNode:child error:&parseError] autorelease];
                
                // only add the feature if it's one we know how to handle
                //
                if ( ! parseError && [feature isKindOfClass:[SimpleKMLFeature class]])
                    [featuresArray addObject:feature];
            }
        }
        
        features = [NSArray arrayWithArray:featuresArray];
    }
    
    return self;
}

- (void)dealloc
{
    [features release];
    
    [super dealloc];
}

@end