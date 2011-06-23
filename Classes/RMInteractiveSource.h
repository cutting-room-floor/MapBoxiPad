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

@protocol RMInteractiveSource

@required

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile;
- (NSString *)interactivityFormatterJavascript;

@end

@interface RMMBTilesTileSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile;
- (NSString *)interactivityFormatterJavascript;

@end

@interface RMTileStreamSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile;
- (NSString *)interactivityFormatterJavascript;

@end

@interface RMCachedTileSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile;
- (NSString *)interactivityFormatterJavascript;

@end

@interface NSData (RMInteractiveSource)

- (NSData *)gzipInflate;

@end