//
//  DSMapBoxTileSetManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"
#import "UIApplication_Additions.h"
#import "FMDatabase.h"

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
    
    [super dealloc];
}

#pragma mark -

- (NSArray *)alternateTileSetPathsOfType:(DSMapBoxTileSetType)tileSetType
{
    NSArray *docsContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    NSArray *alternateFileNames = [docsContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mbtiles'"]];

    NSMutableArray *paths = [NSMutableArray array];
    
    for (NSString *alternateFileName in alternateFileNames)
    {
        NSString *path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], alternateFileName];
        
        FMDatabase *db = [FMDatabase databaseWithPath:path];

        if ( ! [db open])
            continue;
        
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'type'"];
        
        if ([db hadError] && [db close])
            continue;
        
        [results next];
        
        if (tileSetType == DSMapBoxTileSetTypeBaselayer && 
            [[results stringForColumn:@"value"] isEqualToString:@"baselayer"] &&
             ! [[self displayNameForTileSetAtURL:[NSURL fileURLWithPath:path]] isEqualToString:[self defaultTileSetName]])
            [paths addObject:[NSURL fileURLWithPath:path]];
        
        else if (tileSetType == DSMapBoxTileSetTypeOverlay && [[results stringForColumn:@"value"] isEqualToString:@"overlay"])
            [paths addObject:[NSURL fileURLWithPath:path]];
        
        [results close];
        
        [db close];
    }
    
    if (tileSetType == DSMapBoxTileSetTypeBaselayer)
        [paths addObject:@"OpenStreetMap"];

    return [NSArray arrayWithArray:paths];
}

- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL
{
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        return kDSOpenStreetMapURL;
    
    NSString *defaultName = [[tileSetURL relativePath] lastPathComponent];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[tileSetURL relativePath]];
    
    if ( ! [db open])
        return defaultName;
    
    FMResultSet *nameResults = [db executeQuery:@"select value from metadata where name = 'name'"];
    
    if ([db hadError] && [db close])
        return defaultName;
    
    [nameResults next];
    
    NSString *displayName = [nameResults stringForColumn:@"value"];
    
    [nameResults close];
    
    FMResultSet *versionResults = [db executeQuery:@"select value from metadata where name = 'version'"];
    
    if ([db hadError] && [db close])
        return defaultName;
    
    [versionResults next];
    
    NSString *version = [versionResults stringForColumn:@"value"];
    
    [versionResults close];

    [db close];
    
    if ([version isEqualToString:@"1.0"] || [tileSetURL isEqual:[self defaultTileSetURL]])
        return displayName;
    
    else
        return [NSString stringWithFormat:@"%@ (%@)", displayName, version];
    
    return defaultName;
}

- (NSString *)descriptionForTileSetAtURL:(NSURL *)tileSetURL
{
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        return @"Online tiles from the OSM project";
    
    NSString *defaultDescription = @"";
    
    FMDatabase *db = [FMDatabase databaseWithPath:[tileSetURL relativePath]];
    
    if ( ! [db open])
        return defaultDescription;
    
    FMResultSet *descriptionResults = [db executeQuery:@"select value from metadata where name = 'description'"];
    
    if ([db hadError] && [db close])
        return defaultDescription;
    
    [descriptionResults next];
    
    NSString *description = [descriptionResults stringForColumn:@"value"];
    
    [descriptionResults close];
    
    [db close];
    
    return description;
}

- (NSString *)attributionForTileSetAtURL:(NSURL *)tileSetURL
{
    if ([tileSetURL isEqual:kDSOpenStreetMapURL])
        return @"Copyright OpenStreetMap.org Contributors CC-BY-SA";
    
    NSString *defaultAttribution = @"";
    
    FMDatabase *db = [FMDatabase databaseWithPath:[tileSetURL relativePath]];
    
    if ( ! [db open])
        return defaultAttribution;
    
    FMResultSet *attributionResults = [db executeQuery:@"select value from metadata where name = 'attribution'"];
    
    if ([db hadError] && [db close])
        return defaultAttribution;
    
    [attributionResults next];
    
    NSString *attribution = [attributionResults stringForColumn:@"value"];
    
    [attributionResults close];
    
    [db close];
    
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
    return [self displayNameForTileSetAtURL:self.defaultTileSetURL];
}

- (BOOL)deleteTileSetWithName:(NSString *)tileSetName
{
    return NO;
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
    
    NSURL *currentPath = [[self.activeTileSetURL copy] autorelease];
    
    if ([tileSetName isEqualToString:[self displayNameForTileSetAtURL:self.defaultTileSetURL]])
    {
        if ( ! [currentPath isEqual:self.defaultTileSetURL])
            self.activeTileSetURL = [[self.defaultTileSetURL copy] autorelease];
    }
    else
    {
        for (NSURL *alternatePath in [self alternateTileSetPathsOfType:DSMapBoxTileSetTypeBaselayer])
        {
            if ([[self displayNameForTileSetAtURL:alternatePath] isEqualToString:tileSetName])
            {
                self.activeTileSetURL = [[alternatePath copy] autorelease];
                
                break;
            }
        }
    }

    if ( ! [currentPath isEqual:self.activeTileSetURL])
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DSMapBoxTileSetChangedNotification 
                                                                                             object:[NSNumber numberWithBool:animated]]];

    return ! [currentPath isEqual:self.activeTileSetURL];
}

@end