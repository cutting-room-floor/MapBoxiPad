//
//  SimpleKMLLineString.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLGeometry.h"

@interface SimpleKMLLineString : SimpleKMLGeometry
{
    NSArray *coordinates;
}

@property (nonatomic, retain) NSArray *coordinates;

@end