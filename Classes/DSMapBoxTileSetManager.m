//
//  DSMapBoxTileSetManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"

@interface DSMapBoxTileSetManager (DSMapBoxTileSetManagerPrivate)

- (NSString *)documentsFolderPathString;
- (NSArray *)alternateTileSetPaths;
- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL;
- (NSMutableDictionary *)downloadForConnection:(NSURLConnection *)connection;

@end

#pragma mark -

@implementation DSMapBoxTileSetManager

static DSMapBoxTileSetManager *defaultManager;

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
        
        _activeTileSetURL  = [[NSURL fileURLWithPath:path] retain];
        _defaultTileSetURL = [_activeTileSetURL copy];
        _activeDownloads   = [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_activeTileSetURL  release];
    [_defaultTileSetURL release];
    [_activeDownloads   release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)documentsFolderPathString
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    BOOL isDir = NO;
    
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:[userPaths objectAtIndex:0] isDirectory:&isDir] || ! isDir)
        [[NSFileManager defaultManager] createDirectoryAtPath:[userPaths objectAtIndex:0] attributes:nil];
    
    return [userPaths objectAtIndex:0];
}

- (NSArray *)alternateTileSetPaths
{
    NSArray *docsContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self documentsFolderPathString] error:NULL];
    
    NSArray *alternateFileNames = [docsContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mbtiles'"]];

    NSMutableArray *results = [NSMutableArray array];
    
    for (NSString *fileName in alternateFileNames)
        [results addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [self documentsFolderPathString], fileName]]];
    
    return [NSArray arrayWithArray:results];
}

- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL
{
    NSString *base = [[[tileSetURL relativePath] componentsSeparatedByString:@"/"] lastObject];
    
    NSArray *parts = [[base stringByReplacingOccurrencesOfString:@".mbtiles" withString:@""] componentsSeparatedByString:@"_"];
    
    NSAssert([parts count] == 3, @"Unable to parse tile set name");
    
    NSString *displayName = [[parts objectAtIndex:0] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSString *versionName = [[parts objectAtIndex:2] isEqualToString:@"v1"] ? @"" : [NSString stringWithFormat:@" (%@)", [parts objectAtIndex:2]];
    
    return [NSString stringWithFormat:@"%@%@", displayName, versionName];
}

- (NSMutableDictionary *)downloadForConnection:(NSURLConnection *)connection
{
    for (NSMutableDictionary *download in _activeDownloads)
        if ([[download objectForKey:@"connection"] isEqual:connection])
            return download;
    
    return nil;
}

#pragma mark -

- (BOOL)isUsingDefaultTileSet
{
    return [_activeTileSetURL isEqual:_defaultTileSetURL];
}

- (NSString *)defaultTileSetName
{
    return [self displayNameForTileSetAtURL:_defaultTileSetURL];
}

- (NSUInteger)tileSetCount
{
    return [[self alternateTileSetPaths] count] + 1;
}

- (NSArray *)tileSetNames
{
    NSMutableArray *alternateDisplayNames = [NSMutableArray array];
    
    for (NSURL *alternatePath in [self alternateTileSetPaths])
        [alternateDisplayNames addObject:[self displayNameForTileSetAtURL:alternatePath]];
    
    [alternateDisplayNames sortUsingSelector:@selector(compare:)];

    [alternateDisplayNames insertObject:[self defaultTileSetName] atIndex:0];
    
    return [NSArray arrayWithArray:alternateDisplayNames];
}

- (BOOL)importTileSetFromURL:(NSURL *)importURL
{
    for (NSMutableDictionary *download in _activeDownloads)
        if ([[download objectForKey:@"url"] isEqualToString:[importURL absoluteString]])
            return NO;
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:importURL] delegate:self startImmediately:NO];
    
    NSMutableDictionary *newDownload = [NSMutableDictionary dictionaryWithObjectsAndKeys:connection,                                  @"connection", 
                                                                                         [importURL absoluteString],                  @"url", 
                                                                                         [self displayNameForTileSetAtURL:importURL], @"name", 
                                                                                         [NSNumber numberWithFloat:0],                @"completion", 
                                                                                         nil];

    [_activeDownloads addObject:newDownload];
    
    NSString *baseName = [[[importURL relativePath] componentsSeparatedByString:@"/"] lastObject];
    
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", [self documentsFolderPathString], baseName] error:NULL];
    
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    [connection start];
    
    return YES;
}

- (BOOL)deleteTileSetWithName:(NSString *)tileSetName
{
    return NO;
}

- (NSURL *)activeTileSetURL
{
    return _activeTileSetURL;
}

- (NSString *)activeTileSetName
{
    return [self displayNameForTileSetAtURL:_activeTileSetURL];
}

- (NSArray *)activeDownloads
{
    return _activeDownloads;
}

- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName
{
    NSLog(@"activating %@", tileSetName);
    
    NSURL *currentPath = [[_activeTileSetURL copy] autorelease];
    
    if ([tileSetName isEqualToString:[self displayNameForTileSetAtURL:_defaultTileSetURL]])
    {
        if ( ! [currentPath isEqual:_defaultTileSetURL])
        {
            [_activeTileSetURL release];
            _activeTileSetURL = [_defaultTileSetURL copy];
        }
    }
    else
    {
        for (NSURL *alternatePath in [self alternateTileSetPaths])
        {
            if ([[self displayNameForTileSetAtURL:alternatePath] isEqualToString:tileSetName])
            {
                [_activeTileSetURL release];
                _activeTileSetURL = [alternatePath copy];
                
                break;
            }
        }
    }
    
    return ! [currentPath isEqual:_activeTileSetURL];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSDictionary *download = [self downloadForConnection:connection];

    NSLog(@"download error for %@: %@", download, error);
    
    [connection cancel];
    
    NSString *baseName = [[[download objectForKey:@"url"] componentsSeparatedByString:@"/"] lastObject];
    
    NSString *inProgress = [NSString stringWithFormat:@"%@/%@.mbdownload", [self documentsFolderPathString], baseName];
    
    [[NSFileManager defaultManager] removeItemAtPath:inProgress error:NULL];
    
    [_activeDownloads removeObject:download];
    
    [connection release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSMutableDictionary *download = [self downloadForConnection:connection];

    NSLog(@"received response for %@: %@", download, [(NSHTTPURLResponse *)response allHeaderFields]);
    
    NSString *baseName = [[[download objectForKey:@"url"] componentsSeparatedByString:@"/"] lastObject];
    
    [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/%@.mbdownload", [self documentsFolderPathString], baseName]
                                            contents:[NSData data]
                                          attributes:nil];
    
    if ([[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Length"])
        [download setObject:[NSNumber numberWithFloat:[[[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Length"] floatValue]]
                     forKey:@"size"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableDictionary *download = [self downloadForConnection:connection];

    NSLog(@"received %i bytes for %@", [data length], download);
    
    [download setObject:[NSNumber numberWithFloat:([[download objectForKey:@"completion"] floatValue] + (float)[data length])] forKey:@"completion"];
    
    NSString *baseName = [[[download objectForKey:@"url"] componentsSeparatedByString:@"/"] lastObject];

    NSString *inProgress = [NSString stringWithFormat:@"%@/%@.mbdownload", [self documentsFolderPathString], baseName];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:inProgress];
    
    [fileHandle seekToEndOfFile];
    
    [fileHandle writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *download = [self downloadForConnection:connection];

    NSLog(@"finished loading for %@", download);
    
    NSString *baseName = [[[download objectForKey:@"url"] componentsSeparatedByString:@"/"] lastObject];
    
    NSString *inProgress = [NSString stringWithFormat:@"%@/%@.mbdownload", [self documentsFolderPathString], baseName];
    
    [[NSFileManager defaultManager] moveItemAtPath:inProgress 
                                            toPath:[NSString stringWithFormat:@"%@/%@", [self documentsFolderPathString], baseName] 
                                             error:NULL];
    
    [_activeDownloads removeObject:download];

    [connection release];
}

@end