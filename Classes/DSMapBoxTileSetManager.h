//
//  DSMapBoxTileSetManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const DSMapBoxTileSetChangedNotification = @"DSMapBoxTileSetChangedNotification";

typedef enum {
    DSMapBoxTileSetTypeBaselayer = 0,
    DSMapBoxTileSetTypeOverlay   = 1,
} DSMapBoxTileSetType;

@interface DSMapBoxTileSetManager : NSObject
{
    NSURL *_activeTileSetURL;
    NSURL *_defaultTileSetURL;
    NSMutableArray *_activeDownloads;
}

+ (DSMapBoxTileSetManager *)defaultManager;

- (NSArray *)alternateTileSetPathsOfType:(DSMapBoxTileSetType)tileSetType;
- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL;
- (NSString *)descriptionForTileSetAtURL:(NSURL *)tileSetURL;
- (BOOL)isUsingDefaultTileSet;
- (NSString *)defaultTileSetName;
- (BOOL)importTileSetFromURL:(NSURL *)importURL;
- (BOOL)deleteTileSetWithName:(NSString *)tileSetName;
- (NSURL *)activeTileSetURL;
- (NSString *)activeTileSetName;
- (NSArray *)activeDownloads;
- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName;

@end