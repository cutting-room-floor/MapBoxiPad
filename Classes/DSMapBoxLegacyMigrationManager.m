//
//  DSMapBoxLegacyMigrationManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/19/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLegacyMigrationManager.h"

#import "UIApplication_Additions.h"

#import "DSMapBoxDocumentLoadController.h"
#import "DSMapBoxTileSetManager.h"

static DSMapBoxLegacyMigrationManager *defaultManager;

@implementation DSMapBoxLegacyMigrationManager

+ (DSMapBoxLegacyMigrationManager *)defaultManager
{
    @synchronized(@"DSMapBoxLegacyMigrationManager")
    {
        if ( ! defaultManager)
            defaultManager = [[self alloc] init];
    }
    
    return defaultManager;
}

- (void)migrate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ( ! [defaults objectForKey:@"legacyMigration1.3.x"])
    {
        // Routines to migrate saved state & document files containing old OpenStreetMap URLs.
        //
        // Existent in versions through 1.3.x.
        //
        
        NSLog(@"Migrating user data for <= 1.3.x versions...");
        
        NSMutableDictionary *baseMapState;
        NSMutableArray *tileOverlayState;
        
        // app-wide saved state
        //
        if ([defaults objectForKey:@"baseMapState"])
        {
            // base
            //
            baseMapState = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"baseMapState"]];
            
            if ([[baseMapState objectForKey:@"tileSetURL"] isEqualToString:@"OpenStreetMap"])
                [baseMapState setObject:kDSOpenStreetMapURL forKey:@"tileSetURL"];
                
            [defaults setObject:baseMapState forKey:@"baseMapState"];

            // overlays
            //
            tileOverlayState = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"tileOverlayState"]];
            
            for (int i = 0; i < [tileOverlayState count]; i++)
                if ([[tileOverlayState objectAtIndex:i] isEqualToString:@"OpenStreetMap"])
                    [tileOverlayState replaceObjectAtIndex:i withObject:kDSOpenStreetMapURL];

            [defaults setObject:tileOverlayState forKey:@"tileOverlayState"];
        }
        
        // saved docs
        //
        NSString *saveFolder = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
        
        NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:saveFolder]
                                                           includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLCreationDateKey, nil]
                                                                              options:0
                                                                                error:NULL];
        
        for (NSURL *saveFile in saveFiles)
        {
            // preserve timestamp because of doc ordering
            //
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[saveFile path] error:NULL];
            
            NSString *path = [NSString stringWithFormat:@"%@/%@", saveFolder, saveFile];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            
            baseMapState      = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"baseMapState"]];
            tileOverlayState  = [NSMutableArray arrayWithArray:[dict objectForKey:@"tileOverlayState"]];
            
            // base
            //
            if ([[baseMapState objectForKey:@"tileSetURL"] isEqualToString:@"OpenStreetMap"])
                [baseMapState setObject:kDSOpenStreetMapURL forKey:@"tileSetURL"];

            [dict setObject:baseMapState forKey:@"baseMapState"];
            
            // overlays
            //
            NSMutableArray *tileOverlayState = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"tileOverlayState"]];
            
            for (int i = 0; i < [tileOverlayState count]; i++)
                if ([[tileOverlayState objectAtIndex:i] isEqualToString:@"OpenStreetMap"])
                    [tileOverlayState replaceObjectAtIndex:i withObject:kDSOpenStreetMapURL];
            
            [dict setObject:tileOverlayState forKey:@"tileOverlayState"];

            // write it back out
            //
            [dict writeToFile:path atomically:YES];
            [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[saveFile path] error:NULL];
        }
        
        // mark as done
        //
        [defaults setBool:YES forKey:@"legacyMigration1.3.x"];
        [defaults synchronize];
    }
    
    if ( ! [defaults objectForKey:@"legacyMigration1.5.x"])
    {
        // Routines to migration saved state & document files referencing base layers.
        //
        // Existent in versions through 1.5.x.
        //
        
        NSLog(@"Migrating user data for <= 1.5.1 versions...");
        
        NSMutableDictionary *baseMapState;
        NSMutableArray *tileOverlayState;

        // app-wide saved state
        //
        if ([defaults objectForKey:@"baseMapState"])
        {
            // move base to tile layers
            //
            baseMapState     = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"baseMapState"]];
            tileOverlayState = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"tileOverlayState"]];

            if ([baseMapState objectForKey:@"tileSetURL"])
            {
                [tileOverlayState addObject:[baseMapState objectForKey:@"tileSetURL"]];
                [baseMapState removeObjectForKey:@"tileSetURL"];
            
                [defaults setObject:baseMapState     forKey:@"baseMapState"];
                [defaults setObject:tileOverlayState forKey:@"tileOverlayState"];
            }
        }
        
        // saved docs
        //
        NSString *saveFolder = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
        
        NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:saveFolder]
                                                           includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLCreationDateKey, nil]
                                                                              options:0
                                                                                error:NULL];
        
        for (NSURL *saveFile in saveFiles)
        {
            // preserve timestamp because of doc ordering
            //
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[saveFile path] error:NULL];
            
            NSString *path = [NSString stringWithFormat:@"%@/%@", saveFolder, [saveFile path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            
            baseMapState      = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"baseMapState"]];
            tileOverlayState  = [NSMutableArray arrayWithArray:[dict objectForKey:@"tileOverlayState"]];
            
            // move base to tile layers
            //
            if ([baseMapState objectForKey:@"tileSetURL"])
            {
                [tileOverlayState addObject:[baseMapState objectForKey:@"tileSetURL"]];
                [baseMapState removeObjectForKey:@"tileSetURL"];
                
                [dict setObject:baseMapState     forKey:@"baseMapState"];
                [dict setObject:tileOverlayState forKey:@"tileOverlayState"];
                
                // write it back out
                //
                [dict writeToFile:path atomically:YES];
                [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[saveFile path] error:NULL];
            }
        }
        
        // mark as done
        //
        [defaults setBool:YES forKey:@"legacyMigration1.5.x"];
        [defaults synchronize];
    }
}

@end