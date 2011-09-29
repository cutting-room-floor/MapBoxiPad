//
//  DSMapBoxGeoJSONParser.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

typedef enum {
    DSMapBoxGeoJSONGeometryTypePoint      = 0,
    DSMapBoxGeoJSONGeometryTypeLineString = 1,
    DSMapBoxGeoJSONGeometryTypePolygon    = 2,
} DSMapBoxGeoJSONGeometryType;

@interface DSMapBoxGeoJSONParser : NSObject

+ (NSArray *)itemsForGeoJSON:(NSString *)geojson;

@end