//
//  DSMapBoxTileSetManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDSOpenStreetMapURL  [NSURL URLWithString:@"file://localhost/tmp/OpenStreetMap"]
#define kDSOpenStreetMapName @"OpenStreetMap"
#define kDSMapQuestOSMURL    [NSURL URLWithString:@"file://localhost/tmp/MapQuestOSM"]
#define kDSMapQuestOSMName   @"MapQuest Open"

static NSString *const DSMapBoxTileSetChangedNotification = @"DSMapBoxTileSetChangedNotification";

typedef enum {
    DSMapBoxTileSetTypeBaselayer = 0,
    DSMapBoxTileSetTypeOverlay   = 1,
} DSMapBoxTileSetType;

@interface DSMapBoxTileSetManager : NSObject
{
    NSURL *activeTileSetURL;
    NSURL *defaultTileSetURL;
    NSString *defaultTileSetName;
}

@property (nonatomic, retain) NSURL *activeTileSetURL;
@property (nonatomic, retain) NSURL *defaultTileSetURL;

+ (DSMapBoxTileSetManager *)defaultManager;

- (NSArray *)alternateTileSetURLsOfType:(DSMapBoxTileSetType)desiredTileSetType;
- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL;
- (NSString *)descriptionForTileSetAtURL:(NSURL *)tileSetURL;
- (NSString *)attributionForTileSetAtURL:(NSURL *)tileSetURL;
- (BOOL)isUsingDefaultTileSet;
- (NSString *)defaultTileSetName;
- (NSURL *)activeTileSetURL;
- (NSString *)activeTileSetName;
- (NSString *)activeTileSetAttribution;
- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName animated:(BOOL)animated;

@end

#pragma mark -

@interface NSURL (DSMapBoxTileSetManagerExtensions)

- (BOOL)isMBTilesURL;
- (BOOL)isTileStreamURL;

@end