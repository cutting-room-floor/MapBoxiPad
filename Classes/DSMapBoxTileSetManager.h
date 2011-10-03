//
//  DSMapBoxTileSetManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

@interface DSMapBoxTileSetManager : NSObject
{
}

@property (nonatomic, retain) NSURL *defaultTileSetURL;
@property (nonatomic, retain) NSString *defaultTileSetName;

+ (DSMapBoxTileSetManager *)defaultManager;

- (NSArray *)tileSetURLs;
- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL;
- (NSString *)descriptionForTileSetAtURL:(NSURL *)tileSetURL;
- (NSString *)attributionForTileSetAtURL:(NSURL *)tileSetURL;

@end

#pragma mark -

@interface NSURL (DSMapBoxTileSetManagerExtensions)

- (BOOL)isMBTilesURL;
- (BOOL)isTileStreamURL;

@end