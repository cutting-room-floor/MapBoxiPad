//
//  DSMapBoxTileSetManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"

#import "UIApplication_Additions.h"

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

@implementation DSMapBoxTileSetManager

static DSMapBoxTileSetManager *defaultManager;

@synthesize activeTileSetURL;
@synthesize defaultTileSetURL;

+ (DSMapBoxTileSetManager *)defaultManager
{
    @synchronized(@"DSMapBoxTileSetManager")
    {
        if ( ! defaultManager)
            defaultManager = [[self alloc] init];
    }
    
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
        
        activeTileSetURL  = [[NSURL fileURLWithPath:path] retain];
        defaultTileSetURL = [activeTileSetURL copy];
    }
    
    return self;
}

- (void)dealloc
{
    [activeTileSetURL  release];
    [defaultTileSetURL release];
    [defaultTileSetName release];
    
    [super dealloc];
}

#pragma mark -

- (NSArray *)alternateTileSetURLsOfType:(DSMapBoxTileSetType)desiredTileSetType
{
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    NSString *docsPath          = [[UIApplication sharedApplication] documentsFolderPathString];
    NSString *onlineLayersPath  = [NSString stringWithFormat:@"%@/Online Layers", [[UIApplication sharedApplication] preferencesFolderPathString]];
    NSMutableArray *tileSetURLs = [NSMutableArray array];

    // MBTiles in docs folder
    //
    NSArray *localLayers  = [fileManager contentsOfDirectoryAtPath:docsPath error:NULL];

    // TileStream sources in prefs
    //
    NSArray *onlineLayers = [fileManager contentsOfDirectoryAtPath:onlineLayersPath error:NULL];

    // iterate & look for proper type
    //
    for (NSString *localLayer in localLayers)
    {
        NSString *layerPath = [NSString stringWithFormat:@"%@/%@", docsPath, localLayer];
        NSURL *layerURL     = [NSURL fileURLWithPath:layerPath];
        
        if ([[layerURL pathExtension] isEqualToString:@"mbtiles"])
            if ( ! [[self displayNameForTileSetAtURL:layerURL] isEqualToString:[self defaultTileSetName]])
            {
                RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:layerURL];
                
                if ([source layerType] == desiredTileSetType)
                    [tileSetURLs addObject:layerURL];

                // close explicitly to avoid file descriptor problems
                //
                [source release];
            }
    }
    
    for (NSString *onlineLayer in onlineLayers)
    {
        NSString *layerPath = [NSString stringWithFormat:@"%@/%@", onlineLayersPath, onlineLayer];
        NSURL *layerURL     = [NSURL fileURLWithPath:layerPath];
        
        if ([[[layerURL pathExtension] lowercaseString] isEqualToString:@"plist"])
            if ( ! [[self displayNameForTileSetAtURL:layerURL] isEqualToString:[self defaultTileSetName]])
            {
                RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:layerURL];
                
                if ([source layerType] == desiredTileSetType)
                    [tileSetURLs addObject:layerURL];
                
                // close explicitly to avoid file descriptor problems
                //
                [source release];
            }
    }
    
    // add OpenStreetMap & MapQuest for base layers
    //
    if (desiredTileSetType == DSMapBoxTileSetTypeBaselayer)
    {
        [tileSetURLs addObject:kDSOpenStreetMapURL];
        [tileSetURLs addObject:kDSMapQuestOSMURL];
    }

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
        
        [source release];
        
        return name;
    }
    
    if ([tileSetURL isMBTilesURL])
    {
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *name = [source shortName];
        
        [source release];
        
        return name;
    }
    
    return @"";
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
        
        [source release];
        
        return description;
    }
    
    else if ([tileSetURL isMBTilesURL])
    {             
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *description = [source longDescription];
        
        [source release];
        
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
        
        [source release];
        
        return attribution;
    }

    else if ([tileSetURL isMBTilesURL])
    {
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL];
        
        NSString *attribution = [source shortAttribution];
        
        [source release];
        
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

- (BOOL)isUsingDefaultTileSet
{
    return [self.activeTileSetURL isEqual:self.defaultTileSetURL];
}

- (NSString *)defaultTileSetName
{
    // do the actual lookup once
    //
    if ( ! defaultTileSetName)
        defaultTileSetName = [[self displayNameForTileSetAtURL:self.defaultTileSetURL] retain];
    
    return defaultTileSetName;
}

- (NSString *)activeTileSetName
{
    return [self displayNameForTileSetAtURL:self.activeTileSetURL];
}

- (NSString *)activeTileSetAttribution
{
    return [self attributionForTileSetAtURL:self.activeTileSetURL];
}

- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName animated:(BOOL)animated
{
    NSLog(@"activating %@", tileSetName);
    
    NSURL *currentURL = [[self.activeTileSetURL copy] autorelease];
    
    if ([tileSetName isEqualToString:[self displayNameForTileSetAtURL:self.defaultTileSetURL]])
    {
        if ( ! [currentURL isEqual:self.defaultTileSetURL])
            self.activeTileSetURL = [[self.defaultTileSetURL copy] autorelease];
    }
    else
    {
        NSArray *alternateTileSetURLs = [self alternateTileSetURLsOfType:DSMapBoxTileSetTypeBaselayer];
        
        for (NSURL *alternateURL in alternateTileSetURLs)
        {
            if ([[self displayNameForTileSetAtURL:alternateURL] isEqualToString:tileSetName])
            {
                self.activeTileSetURL = [[alternateURL copy] autorelease];
                
                break;
            }
        }
    }

    if ( ! [currentURL isEqual:self.activeTileSetURL])
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DSMapBoxTileSetChangedNotification 
                                                                                             object:[NSNumber numberWithBool:animated]]];

    return ! [currentURL isEqual:self.activeTileSetURL];
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