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
    NSString *_activeTileSetName;
}

+ (DSMapBoxTileSetManager *)defaultManager;

- (BOOL)isUsingDefaultTileSet;
- (NSUInteger)tileSetCount;
- (NSArray *)tileSetNames;
- (BOOL)importTileSetFromURL:(NSURL *)importURL;
- (BOOL)deleteTileSetWithName:(NSString *)tileSetName;
- (NSURL *)activeTileSetURL;
- (NSString *)activeTileSetName;
- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName;

@end