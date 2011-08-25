//
//  RMInteractiveSource.h
//  MapBoxiPad
//
//  Created by Justin Miller on 6/22/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"
#import "RMCachedTileSource.h"

@class RMMapView;

/**
 * Interactivity currently supports two types of output: 'teaser'
 * and 'full'. Ideal for master/detail interfaces or for showing
 * a MapKit-style detail-toggling point callout. 
 */
typedef enum {
    RMInteractiveSourceOutputTypeTeaser = 0,
    RMInteractiveSourceOutputTypeFull   = 1,
} RMInteractiveSourceOutputType;

@protocol RMInteractiveSource

@required

/**
 * Query if a tile source supports interactivity features.
 */
- (BOOL)supportsInteractivity;

/**
 * Get the raw interactivity dictionary for a given point.
 */
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

/**
 * Get the raw interactivity formatter JavaScript for a source.
 */
- (NSString *)interactivityFormatterJavascript;

/**
 * Get the HTML-formatted output for a given point. This is probably 
 * what you want most of the time after determining that a source 
 * supports interactivity.
 */
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMMBTilesTileSource (RMMBTilesTileSourceInteractive) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterJavascript;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMTileStreamSource (RMTileStreamSourceInteractive) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterJavascript;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMCachedTileSource (RMCachedTileSourceInteractive) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
- (NSString *)interactivityFormatterJavascript;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end