//
//  DSMapBoxGeoJSONParser.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSMapBoxGeoJSONParser : NSObject

+ (NSArray *)itemsForGeoJSON:(NSString *)geojson;

@end