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
#import "FMDatabaseQueue.h"

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark Swizzling

// Taken from Mike Ash's 'Swizzle' at http://www.cocoadev.com/index.pl?MethodSwizzling
// Other tips from http://stackoverflow.com/questions/5371601/how-do-i-implement-method-swizzling
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

void DSMapBoxTileSourceInfiniteZoomEnable(Class aClass);

void DSMapBoxTileSourceInfiniteZoomEnable(Class aClass)
{
    DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(minZoom),               @selector(minZoomInfinite));
    DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(maxZoom),               @selector(maxZoomInfinite));    
    DSMapBoxTileSourceInfiniteZoomMethodSwizzle(aClass, @selector(imageForTile:inCache:), @selector(infiniteImageForTile:inCache:));
}

#pragma mark Categories

@implementation RMMBTilesSource (DSMapBoxTileSourceInfiniteZoom)

+ (void)load
{
    DSMapBoxTileSourceInfiniteZoomEnable(self);
}

- (UIImage *)infiniteImageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    if (tile.zoom < [self minZoomNative] || tile.zoom > [self maxZoomNative])
        return [UIImage imageNamed:@"transparent.png"];
    
    return [self infiniteImageForTile:tile inCache:tileCache];
}

- (float)minZoomInfinite
{
    return kMBTilesDefaultMinTileZoom;
}

- (float)minZoomNative
{
    __block CGFloat minZoom;
    
    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];
    
        if ([db hadError])
        {
            minZoom = kMBTilesDefaultMinTileZoom;
        }
        else
        {
            [results next];
    
            minZoom = (CGFloat)[results doubleForColumnIndex:0];
        }
        
        [results close];
    }];
    
    return minZoom;
}

- (float)maxZoomInfinite
{
    return kMBTilesDefaultMaxTileZoom;
}

- (float)maxZoomNative
{
    __block CGFloat maxZoom;
    
    [queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];
         
        if ([db hadError])
        {
            maxZoom = kMBTilesDefaultMaxTileZoom;
        }
        else
        {
            [results next];
            
            maxZoom = (CGFloat)[results doubleForColumnIndex:0];
        }
         
        [results close];
    }];
    
    return maxZoom;
}

@end

@implementation RMMapBoxSource (DSMapBoxTileSourceInfiniteZoom)

+ (void)load
{
    DSMapBoxTileSourceInfiniteZoomEnable(self);
}

- (UIImage *)infiniteImageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    if (tile.zoom < [self minZoomNative] || tile.zoom > [self maxZoomNative] || ! [self.infoDictionary objectForKey:@"tileURL"])
        return [UIImage imageNamed:@"transparent.png"];
    
    return [self infiniteImageForTile:tile inCache:tileCache];
}

- (float)minZoomInfinite
{
    return kMapBoxDefaultMinTileZoom;
}

- (float)minZoomNative
{
    return [[self.infoDictionary objectForKey:@"minzoom"] floatValue];
}

- (float)maxZoomInfinite
{
    return kMapBoxDefaultMaxTileZoom;
}

- (float)maxZoomNative
{
    return [[self.infoDictionary objectForKey:@"maxzoom"] floatValue];
}

@end