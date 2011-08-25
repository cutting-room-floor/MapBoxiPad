//
//  DSMapBoxTileSourceInfiniteZoom.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/25/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxTileSourceInfiniteZoom.h"

#import "FMDatabase.h"

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark Min/Max Zoom Swizzling

// Taken from Mike Ash's 'Swizzle' at http://www.cocoadev.com/index.pl?MethodSwizzling
//
void DSMapBoxTileSourceInfiniteZoomMethodSwizzle(Class tileSourceClass, SEL originalSelector, SEL alternateSelector);

void DSMapBoxTileSourceInfiniteZoomMethodSwizzle(Class tileSourceClass, SEL originalSelector, SEL alternateSelector)
{
    Method originalMethod  = nil;
    Method alternateMethod = nil;
    
    originalMethod  = class_getInstanceMethod(tileSourceClass, originalSelector);
    alternateMethod = class_getInstanceMethod(tileSourceClass, alternateSelector);
    
    if(class_addMethod(tileSourceClass, originalSelector, method_getImplementation(alternateMethod), method_getTypeEncoding(alternateMethod)))
        class_replaceMethod(tileSourceClass, alternateSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));

    else
        method_exchangeImplementations(originalMethod, alternateMethod);
}

#pragma mark Public Implementation

@implementation DSMapBoxTileSourceInfiniteZoom

+ (BOOL)enableInfiniteZoomForClasses:(NSArray *)tileSourceClasses
{
    for (Class tileSourceClass in tileSourceClasses)
    {
        if ([tileSourceClass conformsToProtocol:@protocol(RMTileSource)])
        {
            DSMapBoxTileSourceInfiniteZoomMethodSwizzle(tileSourceClass, @selector(maxZoom), @selector(maxZoomInfinite));
            DSMapBoxTileSourceInfiniteZoomMethodSwizzle(tileSourceClass, @selector(minZoom), @selector(minZoomInfinite));
        }
    }
    
    return YES;
}

@end

#pragma mark Category Implementations

@implementation RMMBTilesTileSource (DSMapBoxTileSourceInfiniteZoom)

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