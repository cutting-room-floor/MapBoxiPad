//
//  DSMapBoxTileSourceInfiniteZoom.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/25/11.
//  Copyright 2011 Development Seed. All rights reserved.
//
//  All of this swizzling business is done so that we don't have 
//  to subclass our tile sources in order to add infinite zoom 
//  support. It should be kosher, but if ever run into problems 
//  with it, we'll just have to subclass and replace all uses
//  throughout the app with our custom class which handles the 
//  infinite zooming abstraction. 
//

#import "DSMapBoxTileSourceInfiniteZoom.h"

#import "RMTileImage.h"

#import "FMDatabase.h"

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark Min/Max Zoom Swizzling

// Taken from Mike Ash's 'Swizzle' at http://www.cocoadev.com/index.pl?MethodSwizzling
//
void DSMapBoxTileSourceInfiniteZoomMethodSwizzle(Class aClass, SEL originalSelector, SEL alternateSelector);

void DSMapBoxTileSourceInfiniteZoomMethodSwizzle(Class aClass, SEL originalSelector, SEL alternateSelector)
{
    Method originalMethod  = nil;
    Method alternateMethod = nil;
    
    originalMethod  = class_getInstanceMethod(aClass, originalSelector);
    alternateMethod = class_getInstanceMethod(aClass, alternateSelector);
    
    if (class_addMethod(aClass, originalSelector, method_getImplementation(alternateMethod), method_getTypeEncoding(alternateMethod)))
        class_replaceMethod(aClass, alternateSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));

    else
        method_exchangeImplementations(originalMethod, alternateMethod);
}

#pragma mark Public Implementation

@implementation DSMapBoxTileSourceInfiniteZoom

+ (BOOL)enableInfiniteZoomForClasses:(NSArray *)classes
{
    for (Class aClass in classes)
    {
        if ([aClass conformsToProtocol:@protocol(RMTileSource)])
        {
            // swap in min/max zoom methods to answer all calls
            //
            if ([aClass instancesRespondToSelector:@selector(minZoomInfinite)] && [aClass instancesRespondToSelector:@selector(maxZoomInfinite)])
            {
                DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(minZoom), @selector(minZoomInfinite));
                DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(maxZoom), @selector(maxZoomInfinite));
            }
            
            // swap in tile image method to provide out-of-bounds image
            //
            if ([aClass instancesRespondToSelector:@selector(tileImageOriginal:)] && [aClass instancesRespondToSelector:@selector(tileImageInfinite:)])
            {
                DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(tileImageOriginal:), @selector(tileImage:));
                DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(tileImage:),         @selector(tileImageInfinite:));
            }
        }
    }
    
    return YES;
}

@end

#pragma mark Category Implementations

@implementation RMMBTilesTileSource (DSMapBoxTileSourceInfiniteZoom)

- (RMTileImage *)tileImageOriginal:(RMTile)tile
{
    // dummy method that gets pointed at native tileImage:
    //
    return nil;
}

- (RMTileImage *)tileImageInfinite:(RMTile)tile
{
    // if out of zoom bounds, return a default image
    //
    if ([self layerType] == RMMBTilesLayerTypeBaselayer && (tile.zoom < [self minZoomNative] || tile.zoom > [self maxZoomNative]))
        return [RMTileImage imageForTile:tile withData:UIImagePNGRepresentation([UIImage imageNamed:@"caution.png"])];
    
    // else return the real image
    //
    return [self tileImageOriginal:tile];
}

- (float)minZoomInfinite
{
    return kMBTilesDefaultMinTileZoom;
}

- (float)minZoomNative
{
    FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];
    
    if ([db hadError])
        return kMBTilesDefaultMinTileZoom;
    
    [results next];
    
    double minZoom = [results doubleForColumnIndex:0];
    
    [results close];
    
    return (float)minZoom;
}

- (float)maxZoomInfinite
{
    return kMBTilesDefaultMaxTileZoom;
}

- (float)maxZoomNative
{
    FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];
    
    if ([db hadError])
        return kMBTilesDefaultMaxTileZoom;
    
    [results next];
    
    double maxZoom = [results doubleForColumnIndex:0];
    
    [results close];
    
    return (float)maxZoom;
}

@end

@implementation RMTileStreamSource (DSMapBoxTileSourceInfiniteZoom)

- (RMTileImage *)tileImageOriginal:(RMTile)tile
{
    return nil;
}

- (RMTileImage *)tileImageInfinite:(RMTile)tile
{
    if ([self layerType] == RMTileStreamLayerTypeBaselayer && (tile.zoom < [self minZoomNative] || tile.zoom > [self maxZoomNative]))
        return [RMTileImage imageForTile:tile withData:UIImagePNGRepresentation([UIImage imageNamed:@"caution.png"])];
    
    return [self tileImageOriginal:tile];
}

- (float)minZoomInfinite
{
    return kTileStreamDefaultMinTileZoom;
}

- (float)minZoomNative
{
    return [[self.infoDictionary objectForKey:@"minzoom"] floatValue];
}

- (float)maxZoomInfinite
{
    return kTileStreamDefaultMaxTileZoom;
}

- (float)maxZoomNative
{
    return [[self.infoDictionary objectForKey:@"maxzoom"] floatValue];
}

@end