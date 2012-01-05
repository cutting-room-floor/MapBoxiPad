//
//  DSMapBoxTileSetManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"

#import "UIApplication_Additions.h"

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

@implementation DSMapBoxTileSetManager

@synthesize defaultTileSetURL;
@synthesize defaultTileSetName;

+ (DSMapBoxTileSetManager *)defaultManager
{
    static dispatch_once_t token;
    static DSMapBoxTileSetManager *defaultManager = nil;
    
    dispatch_once(&token, ^{ defaultManager = [[self alloc] init]; });
    
    return defaultManager;
}

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        NSArray *bundledTileSets = [[NSBundle mainBundle] pathsForResourcesOfType:@"mbtiles" inDirectory:nil];
        
        NSAssert([bundledTileSets count] > 0, @"No bundled tile sets found in application");
        
        NSString *path = [[bundledTileSets sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
        
        defaultTileSetURL = [NSURL fileURLWithPath:path];
    }
    
    return self;
}

#pragma mark -

- (NSArray *)tileSetURLs
{
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    NSString *docsPath          = [[UIApplication sharedApplication] documentsFolderPath];
    NSString *onlineLayersPath  = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kTileStreamFolderName];
    NSMutableArray *tileSetURLs = [NSMutableArray array];

    // MBTiles in docs folder
    //
    NSArray *localLayers  = [fileManager contentsOfDirectoryAtPath:docsPath error:NULL];

    // TileStream sources in prefs
    //
    NSArray *onlineLayers = [fileManager contentsOfDirectoryAtPath:onlineLayersPath error:NULL];

    // iterate each & add to list
    //
    for (NSString *localLayer in localLayers)
    {
        NSString *layerPath = [NSString stringWithFormat:@"%@/%@", docsPath, localLayer];
        NSURL *layerURL     = [NSURL fileURLWithPath:layerPath];
        
        if ([[layerURL pathExtension] isEqualToString:@"mbtiles"])
            if ( ! [[self displayNameForTileSetAtURL:layerURL] isEqualToString:self.defaultTileSetName])
                [tileSetURLs addObject:layerURL];
    }
    
    for (NSString *onlineLayer in onlineLayers)
    {
        NSString *layerPath = [NSString stringWithFormat:@"%@/%@", onlineLayersPath, onlineLayer];
        NSURL *layerURL     = [NSURL fileURLWithPath:layerPath];
        
        if ([[[layerURL pathExtension] lowercaseString] isEqualToString:@"plist"])
            if ( ! [[self displayNameForTileSetAtURL:layerURL] isEqualToString:self.defaultTileSetName])
                [tileSetURLs addObject:layerURL];
    }
    
    // add OpenStreetMap & MapQuest
    //
    [tileSetURLs addObject:kDSOpenStreetMapURL];
    [tileSetURLs addObject:kDSMapQuestOSMURL];

    return [NSArray arrayWithArray:tileSetURLs];
}

- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL
{
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        return kDSOpenStreetMapName;

    if ([tileSetURL isEqual:kDSMapQuestOSMURL])
        return kDSMapQuestOSMName;

    if ([tileSetURL isTileStreamURL])
    {
        RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:tileSetURL];
        
        NSString *name = [source shortName];
        
        return name;
    }
    
    if ([tileSetURL isMBTilesURL])
    {
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *name = [source shortName];
        
        return name;
    }
    
    return @"(untitled)";
}

- (NSString *)descriptionForTileSetAtURL:(NSURL *)tileSetURL
{
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        return @"Collaboratively-edited world map project";

    else if ([tileSetURL isEqual:kDSMapQuestOSMURL])
        return @"Open map tiles from MapQuest";

    else if ([tileSetURL isTileStreamURL])
    {
        RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:tileSetURL];
        
        NSString *description = [source longDescription];
        
        return description;
    }
    
    else if ([tileSetURL isMBTilesURL])
    {             
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *description = [source longDescription];
        
        return description;
    }

    return @"";
}

- (NSString *)attributionForTileSetAtURL:(NSURL *)tileSetURL
{
    NSString *attribution = @"";
    
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        attribution = @"Copyright OpenStreetMap.org Contributors CC-BY-SA";

    else if ([tileSetURL isEqual:kDSMapQuestOSMURL])
        attribution = @"Tiles Courtesy of MapQuest";
    
    else if ([tileSetURL isTileStreamURL])
    {
        RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:tileSetURL];
        
        NSString *attribution = [source shortAttribution];
        
        return attribution;
    }

    else if ([tileSetURL isMBTilesURL])
    {
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *attribution = [source shortAttribution];
        
        return attribution;        
    }
        
    // strip HTML
    //
    NSScanner *scanner = [NSScanner scannerWithString:attribution];
    NSString  *text    = nil;
    
    while ( ! [scanner isAtEnd])
    {
        [scanner scanUpToString:@"<" intoString:NULL];
        [scanner scanUpToString:@">" intoString:&text];
        
        attribution = [attribution stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    return [attribution stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark -

- (NSString *)defaultTileSetName
{
    // do the actual lookup once
    //
    if ( ! defaultTileSetName)
        defaultTileSetName = [self displayNameForTileSetAtURL:self.defaultTileSetURL];
    
    return defaultTileSetName;
}

@end

#pragma mark -

@implementation NSURL (DSMapBoxTileSetManagerExtensions)

- (BOOL)isMBTilesURL
{
    return ([self isFileURL] && [[[self pathExtension] lowercaseString] isEqualToString:@"mbtiles"]);
}
             
- (BOOL)isTileStreamURL
{
    return ([self isFileURL] && [[[self pathExtension] lowercaseString] isEqualToString:@"plist"]);
}

@end