//
//  SimpleKMLPolygon.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#polygon
//

#import "SimpleKMLGeometry.h"

@class SimpleKMLLinearRing;

@interface SimpleKMLPolygon : SimpleKMLGeometry
{
    SimpleKMLLinearRing *outerBoundary;
    SimpleKMLLinearRing *firstInnerBoundary;
    NSArray *innerBoundaries;
}

@property (nonatomic, retain) SimpleKMLLinearRing *outerBoundary;
@property (nonatomic, retain) SimpleKMLLinearRing *firstInnerBoundary;
@property (nonatomic, retain) NSArray *innerBoundaries;

@end