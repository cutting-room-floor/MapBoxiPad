//
//  SimpleKMLPlacemark.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#placemark
//

#import "SimpleKMLFeature.h"

@class SimpleKMLGeometry;
@class SimpleKMLPoint;
@class SimpleKMLPolygon;
@class SimpleKMLLinearRing;

@interface SimpleKMLPlacemark : SimpleKMLFeature
{
    SimpleKMLGeometry *geometry;
}

@property (nonatomic, retain) SimpleKMLGeometry *geometry;
@property (nonatomic, retain) SimpleKMLPoint *point;
@property (nonatomic, retain) SimpleKMLPolygon *polygon;
@property (nonatomic, retain) SimpleKMLLinearRing *linearRing;

@end