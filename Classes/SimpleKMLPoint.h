//
//  SimpleKMLPoint.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#point
//

#import "SimpleKMLGeometry.h"
#import <CoreLocation/CoreLocation.h>

@interface SimpleKMLPoint : SimpleKMLGeometry
{
    CLLocation *_location;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end