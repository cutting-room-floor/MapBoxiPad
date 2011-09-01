//
//  DSMapBoxGeoJSONParser.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxGeoJSONParser.h"

#import "JSONKit.h"

#import <CoreLocation/CoreLocation.h>

@implementation DSMapBoxGeoJSONParser

+ (NSArray *)itemsForGeoJSON:(NSString *)geojson
{
    NSMutableArray *items = [NSMutableArray array];
    
    id json = [geojson objectFromJSONString];
    
    if ([json isKindOfClass:[NSDictionary class]])
    {
        json = (NSDictionary *)json;
        
        if ([[json objectForKey:@"type"] isEqual:@"FeatureCollection"] && [json objectForKey:@"features"])
        {
            for (NSDictionary *feature in [json objectForKey:@"features"])
            {
                int itemCount;
                
                if ([[feature objectForKey:@"type"] isEqual:@"Feature"])
                {
                    NSString *itemID;
                    
                    if ([feature objectForKey:@"id"])
                        itemID = [feature objectForKey:@"id"];
                    
                    else
                        itemID = [NSString stringWithFormat:@"%i", ++itemCount];
                    
                    NSNumber *geometryType;
                    
                    NSMutableArray *geometries = [NSMutableArray array];
                    
                    if ([feature objectForKey:@"geometry"])
                    {
                        NSDictionary *geometry = [feature objectForKey:@"geometry"];
                        
                        if ([[geometry objectForKey:@"type"] isEqual:@"Point"] && [[geometry objectForKey:@"coordinates"] isKindOfClass:[NSArray class]])
                        {
                            geometryType = [NSNumber numberWithInt:DSMapBoxGeoJSONGeometryTypePoint];
                            
                            CLLocation *location = [[[CLLocation alloc] initWithLatitude:[[[geometry objectForKey:@"coordinates"] objectAtIndex:1] doubleValue] 
                                                                               longitude:[[[geometry objectForKey:@"coordinates"] objectAtIndex:0] doubleValue]] autorelease];
                            
                            [geometries addObject:location];
                        }
                        else if ([[geometry objectForKey:@"type"] isEqual:@"LineString"] && [[geometry objectForKey:@"coordinates"] isKindOfClass:[NSArray class]])
                        {
                            geometryType = [NSNumber numberWithInt:DSMapBoxGeoJSONGeometryTypeLineString];
                            
                            if ([[geometry objectForKey:@"coordinates"] count] >= 2)
                            {
                                for (NSArray *pair in [geometry objectForKey:@"coordinates"])
                                {
                                    CLLocation *location = [[[CLLocation alloc] initWithLatitude:[[pair objectAtIndex:1] doubleValue] 
                                                                                       longitude:[[pair objectAtIndex:0] doubleValue]] autorelease];
                                    
                                    [geometries addObject:location];
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
                    
                    if ([geometries count] && properties)
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