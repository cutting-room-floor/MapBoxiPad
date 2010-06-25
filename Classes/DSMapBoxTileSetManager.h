//
//  DSMapBoxTileSetManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSMapBoxTileSetManager : NSObject
{
    NSURL *_activeTileSetURL;
    NSURL *_defaultTileSetURL;
    NSMutableArray *_activeDownloads;
}

+ (DSMapBoxTileSetManager *)defaultManager;

- (BOOL)isUsingDefaultTileSet;
- (NSString *)defaultTileSetName;
- (NSUInteger)tileSetCount;
- (NSArray *)tileSetNames;
- (BOOL)importTileSetFromURL:(NSURL *)importURL;
- (BOOL)deleteTileSetWithName:(NSString *)tileSetName;
- (NSURL *)activeTileSetURL;
- (NSString *)activeTileSetName;
- (NSArray *)activeDownloads;
- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName;

@end