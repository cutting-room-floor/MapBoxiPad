//
//  SimpleKMLDocument.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLDocument.h"
#import "SimpleKMLStyle.h"
#import "SimpleKMLFeature.h"

@implementation SimpleKMLDocument

@synthesize sharedStyles;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        NSMutableArray *parsedStyles = [NSMutableArray array];
        
        for (CXMLNode *child in [node children])
        {
            Class childClass = NSClassFromString([NSString stringWithFormat:@"SimpleKML%@", [child name]]);
            
            if (childClass)
            {
                id thisChild = [[[childClass alloc] initWithXMLNode:child error:NULL] autorelease];
                
                if (thisChild && [thisChild isKindOfClass:[SimpleKMLStyle class]])
                    [parsedStyles addObject:thisChild];
            }
        }
        
        sharedStyles = [[NSArray arrayWithArray:parsedStyles] retain];

        for (SimpleKMLFeature *feature in features)
            if (feature.sharedStyleID && ! feature.sharedStyle)
                feature.sharedStyle = [self sharedStyleWithID:feature.sharedStyleID];
    }
    
    return self;
}

- (void)dealloc
{
    [sharedStyles release];
    
    [super dealloc];
}

#pragma mark -

- (SimpleKMLStyle *)sharedStyleWithID:(NSString *)styleID
{
    for (SimpleKMLStyle *style in self.sharedStyles)
        if ([[style objectID] isEqualToString:styleID])
            return style;
    
    return nil;
}

@end