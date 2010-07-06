//
//  SimpleKMLLinearRing.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#linearring
//

#import "SimpleKMLGeometry.h"

@interface SimpleKMLLinearRing : SimpleKMLGeometry
{
    NSArray *coordinates;
}

@property (nonatomic, retain) NSArray *coordinates;

@end