//
//  DSMapBoxGeoJSONParser.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxGeoJSONParser.h"

#import <CoreLocation/CoreLocation.h>

#import "RMProjection.h"

@interface DSMapBoxGeoJSONParser ()

+ (CLLocation *)locationFromCoordinates:(NSArray *)coordinates;

@end

#pragma mark -

@implementation DSMapBoxGeoJSONParser

+ (CLLocation *)locationFromCoordinates:(NSArray *)coordinates
{
    double a = [[coordinates objectAtIndex:0] doubleValue];
    double b = [[coordinates objectAtIndex:1] doubleValue];
    
    if (a < -180 || a > 180 || b < -90 || b > 90)
    {
        RMProjectedPoint point = {
            .x = a,
            .y = b,
        };
        
        CLLocationCoordinate2D latLong = [[RMProjection googleProjection] projectedPointToCoordinate:point];
        
        return [[CLLocation alloc] initWithLatitude:latLong.latitude longitude:latLong.longitude];
    }
    
    else
        return [[CLLocation alloc] initWithLatitude:b longitude:a];

    return [[CLLocation alloc] initWithLatitude:0 longitude:0];
}

+ (NSArray *)itemsForGeoJSON:(NSString *)geojson
{
    NSMutableArray *items = [NSMutableArray array];
    
    id json = [NSJSONSerialization JSONObjectWithData:[geojson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    
    if ([json isKindOfClass:[NSDictionary class]])
    {
        json = (NSDictionary *)json;
        
        if ([[json objectForKey:@"type"] isEqual:@"FeatureCollection"] && [json objectForKey:@"features"])
        {
            // first expand out GeometryCollection items, which could be e.g. Point or MultiPoint
            //
            NSMutableArray *expandedGeometries = [NSMutableArray array];
            
            for (NSDictionary *feature in [json objectForKey:@"features"])
            {
                if ([[feature objectForKey:@"type"] isEqual:@"GeometryCollection"])
                {
                    for (NSDictionary *geometry in [feature objectForKey:@"geometries"])
                    {
                        NSMutableDictionary *expandedGeometry = [NSMutableDictionary dictionaryWithObject:@"Feature" forKey:@"type"];
                        
                        // copy id & properties into instances
                        //
                        if ([feature objectForKey:@"id"])
                            [expandedGeometry setObject:[feature objectForKey:@"id"] forKey:@"id"];
                        
                        if ([feature objectForKey:@"properties"])
                            [expandedGeometry setObject:[feature objectForKey:@"properties"] forKey:@"properties"];
                        
                        // add in individual geometry
                        //
                        [expandedGeometry setObject:geometry forKey:@"geometry"];
                        
                        // save for single/multi iteration
                        //
                        [expandedGeometries addObject:expandedGeometry];
                    }
                }

                // just add in regular features
                //
                else
                    [expandedGeometries addObject:feature];
            }
            
            // then iterate all of these geometry features, single or multi
            //
            NSMutableArray *expandedFeatures = [NSMutableArray array];
            
            for (NSDictionary *feature in expandedGeometries)
            {
                // keep normal Point/LineString/etc. features
                //
                if ([[feature objectForKey:@"type"] isEqual:@"Feature"] && ! [[feature valueForKeyPath:@"geometry.type"] hasPrefix:@"Multi"])
                    [expandedFeatures addObject:feature];
                
                // expand MultiPoint/MultiLineString/etc. into multiple instances of base types
                //
                else
                {
                    for (NSArray *subfeatureCoordinates in [feature valueForKeyPath:@"geometry.coordinates"])
                    {
                        NSString *subfeatureGeometryType = [[feature valueForKeyPath:@"geometry.type"] stringByReplacingOccurrencesOfString:@"Multi" withString:@""];

                        NSMutableDictionary *expandedFeature = [NSMutableDictionary dictionaryWithObject:[feature objectForKey:@"type"] 
                                                                                                  forKey:@"type"];
                    
                        NSMutableDictionary *subfeatureGeometry = [NSMutableDictionary dictionaryWithObject:subfeatureGeometryType
                                                                                                     forKey:@"type"];
                    
                        [expandedFeature setObject:subfeatureGeometry 
                                            forKey:@"geometry"];
                        
                        // copy id & properties into instances
                        //
                        if ([feature objectForKey:@"id"])
                            [expandedFeature setObject:[feature objectForKey:@"id"] forKey:@"id"];

                        if ([feature objectForKey:@"properties"])
                            [expandedFeature setObject:[feature objectForKey:@"properties"] forKey:@"properties"];
                        
                        // adapt geometry into instance
                        //
                        [subfeatureGeometry setObject:subfeatureCoordinates 
                                               forKey:@"coordinates"];
                        
                        // add to expanded features for further parsing
                        //
                        [expandedFeatures addObject:expandedFeature];
                    }
                }
            }

            // iterate all individual features
            //
            for (NSDictionary *feature in expandedFeatures)
            {
                int itemCount = 0;
                
                if ([[feature objectForKey:@"type"] isEqual:@"Feature"])
                {
                    NSString *itemID;
                    
                    if ([feature objectForKey:@"id"])
                        itemID = [feature objectForKey:@"id"];
                    
                    else
                        itemID = [NSString stringWithFormat:@"%i", ++itemCount];
                    
                    NSNumber *geometryType = [NSNumber numberWithInt:-1];
                    
                    NSMutableArray *geometries = [NSMutableArray array];
                    
                    if ([feature objectForKey:@"geometry"])
                    {
                        NSDictionary *geometry = [feature objectForKey:@"geometry"];
                        
                        // Points should have a single set of coordinates in an array
                        //
                        if ([[geometry objectForKey:@"type"] isEqual:@"Point"] && 
                            [[geometry objectForKey:@"coordinates"] isKindOfClass:[NSArray class]] &&
                            [[geometry objectForKey:@"coordinates"] count] >= 2)
                        {
                            geometryType = [NSNumber numberWithInt:DSMapBoxGeoJSONGeometryTypePoint];
                            
                            [geometries addObject:[DSMapBoxGeoJSONParser locationFromCoordinates:[geometry objectForKey:@"coordinates"]]];
                        }
                        
                        // LineStrings should have an array of two or more coordinates, which are arrays themselves of 2+ members
                        //
                        else if ([[geometry objectForKey:@"type"] isEqual:@"LineString"] && 
                                 [[geometry objectForKey:@"coordinates"] isKindOfClass:[NSArray class]] &&
                                 [[geometry objectForKey:@"coordinates"] count] >= 2 &&
                                 [[[geometry objectForKey:@"coordinates"] filteredArrayUsingPredicate:
                                     [NSPredicate predicateWithFormat:@"NOT SELF isKindOfClass:%@ OR @count < 2", [NSArray class]]] count] == 0)
                        {
                            geometryType = [NSNumber numberWithInt:DSMapBoxGeoJSONGeometryTypeLineString];
                            
                            for (NSArray *pair in [geometry objectForKey:@"coordinates"])
                                [geometries addObject:[DSMapBoxGeoJSONParser locationFromCoordinates:pair]];
                        }
                        
                        // Polygons should have an array of one or more coordinates, which are LinearRings (closed LineStrings)
                        //
                        else if ([[geometry objectForKey:@"type"] isEqual:@"Polygon"] && 
                                 [[geometry objectForKey:@"coordinates"] isKindOfClass:[NSArray class]] &&
                                 [[geometry objectForKey:@"coordinates"] count])
                        {
                            geometryType = [NSNumber numberWithInt:DSMapBoxGeoJSONGeometryTypePolygon];
                            
                            for (id linearRing in [geometry objectForKey:@"coordinates"])
                            {
                                // LinearRing geometries should have four or more coordinates
                                //
                                if ([linearRing isKindOfClass:[NSArray class]] && 
                                    [linearRing count] >= 4)
                                {
                                    // coordinates should be arrays & first/last lat & long should be identical
                                    //
                                    if ([[linearRing filteredArrayUsingPredicate:
                                            [NSPredicate predicateWithFormat:@"NOT SELF isKindOfClass:%@ OR @count < 2", [NSArray class]]] count] == 0 &&
                                        [[[linearRing objectAtIndex:0] objectAtIndex:0] isEqual:[[linearRing lastObject] objectAtIndex:0]] && 
                                        [[[linearRing objectAtIndex:0] objectAtIndex:1] isEqual:[[linearRing lastObject] objectAtIndex:1]])
                                    {
                                        NSMutableArray *geometry = [NSMutableArray array];
                                        
                                        for (NSArray *pair in linearRing)
                                            [geometry addObject:[DSMapBoxGeoJSONParser locationFromCoordinates:pair]];
                                        
                                        [geometries addObject:geometry];
                                    }
                                }
                            }
                        }
                    }
                    
                    NSDictionary *properties = nil;
                    
                    if ([feature objectForKey:@"properties"])
                    {
                        if ([geometryType intValue] == DSMapBoxGeoJSONGeometryTypePoint)
                        {
                            NSMutableDictionary *cleanedProperties = [NSMutableDictionary dictionary];
                            
                            for (NSString *key in [[feature objectForKey:@"properties"] allKeys])
                            {
                                /**
                                 * Properties are usually spelled out in a machine-oriented way, 
                                 * for example, `home_province = Afghan`. We'll just take the keys,
                                 * remove underscores, and capitalize first letters to get something
                                 * a bit more presentable from raw input.
                                 */
                                
                                NSString *prettyKey = [[key stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString];
                                
                                [cleanedProperties setObject:[[feature objectForKey:@"properties"] objectForKey:key] forKey:prettyKey];
                            }
                            
                            properties = [NSDictionary dictionaryWithDictionary:cleanedProperties];
                        }
                        
                        else
                            properties = [feature objectForKey:@"properties"];
                    }
                    
                    // include any features with geometries, but for points, only if they have properties to display
                    //
                    if ([geometries count] && (properties || [geometryType intValue] != DSMapBoxGeoJSONGeometryTypePoint))
                    {
                        NSDictionary *featureDictionary = [NSDictionary dictionaryWithObjectsAndKeys:itemID,                              @"id",
                                                                                                     geometryType,                        @"type",
                                                                                                     [NSArray arrayWithArray:geometries], @"geometries", 
                                                                                                     properties,                          @"properties", 
                                                                                                     nil];
                        
                        [items addObject:featureDictionary];
                    }
                }
            }
        }
    }
    
    return [NSArray arrayWithArray:items];
}

@end