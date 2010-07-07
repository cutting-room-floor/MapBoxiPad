//
//  SimpleKMLPolygon.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLPolygon.h"
#import "SimpleKMLLinearRing.h"

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLPolygon

@synthesize outerBoundary;
@synthesize firstInnerBoundary;
@synthesize innerBoundaries;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        outerBoundary      = nil;
        firstInnerBoundary = nil;
        innerBoundaries    = nil;
        
        NSMutableArray *parsedInnerBoundaries = [NSMutableArray array];
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"outerBoundaryIs"])
            {
                NSArray *boundaryChildren = [child children];
                
                // there should only be one child of this boundary
                //
                if ([boundaryChildren count] != 3)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid number of LinearRings in Polygon boundary)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                outerBoundary = [[SimpleKMLLinearRing alloc] initWithXMLNode:[boundaryChildren objectAtIndex:1] error:NULL];
            }
            else if ([[child name] isEqualToString:@"innerBoundaryIs"])
            {
                NSArray *boundaryChildren = [child children];
                
                // there should only be one child of this boundary
                //
                if ([boundaryChildren count] != 3)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid number of LinearRings in Polygon boundary)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                SimpleKMLLinearRing *thisBoundary = [[[SimpleKMLLinearRing alloc] initWithXMLNode:[boundaryChildren objectAtIndex:1] error:NULL] autorelease];
                
                if ( ! firstInnerBoundary)
                    firstInnerBoundary = thisBoundary;
                
                [parsedInnerBoundaries addObject:thisBoundary];
            }
        }
        
        innerBoundaries = [[NSArray arrayWithArray:parsedInnerBoundaries] retain];

        // there should be one outer boundary
        //
        if ( ! outerBoundary)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Missing outer boundary in Polygon)" 
                                                                 forKey:NSLocalizedFailureReasonErrorKey];
            
            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
            
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [outerBoundary release];
    [firstInnerBoundary release];
    [innerBoundaries release];
    
    [super dealloc];
}

@end