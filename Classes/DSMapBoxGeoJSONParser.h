//
//  DSMapBoxGeoJSONParser.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DSMapBoxGeoJSONGeometryTypePoint      = 0,
    DSMapBoxGeoJSONGeometryTypeLineString = 1,
} DSMapBoxGeoJSONGeometryType;

@interface DSMapBoxGeoJSONParser : NSObject

+ (NSArray *)itemsForGeoJSON:(NSString *)geojson;

@end