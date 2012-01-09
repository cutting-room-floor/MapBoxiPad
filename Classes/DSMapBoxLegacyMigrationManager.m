//
//  DSMapBoxLegacyMigrationManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/19/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLegacyMigrationManager.h"

#import "DSMapBoxDocumentLoadController.h"

@implementation DSMapBoxLegacyMigrationManager

+ (DSMapBoxLegacyMigrationManager *)defaultManager
{
    static dispatch_once_t token;
    static DSMapBoxLegacyMigrationManager *defaultManager = nil;
    
    dispatch_once(&token, ^{ defaultManager = [[self alloc] init]; });
    
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
        NSString *saveFolder = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDSSaveFolderName];
        
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
            
            // base
            //
            if ([[baseMapState objectForKey:@"tileSetURL"] isEqualToString:@"OpenStreetMap"])
                [baseMapState setObject:kDSOpenStreetMapURL forKey:@"tileSetURL"];

            [dict setObject:baseMapState forKey:@"baseMapState"];
            
            // overlays
            //
            tileOverlayState  = [NSMutableArray arrayWithArray:[dict objectForKey:@"tileOverlayState"]];

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
        // Routines to migrate saved state & document files referencing base layers. (#21)
        // Routines to migrate absolute tile/data paths in saved documents. (#107)
        //
        // Existent in versions through 1.5.x.
        //
        
        NSLog(@"Migrating user data for <= 1.5.1 versions...");
        
        NSMutableDictionary *baseMapState;
        NSMutableArray *tileOverlayState;
        NSMutableArray *dataOverlayState;

        // app-wide saved state
        //
        if ([defaults objectForKey:@"baseMapState"])
        {
            // move base to tile layers
            //
            baseMapState     = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"baseMapState"]];
            tileOverlayState = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"tileOverlayState"]];
            dataOverlayState = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"dataOverlayState"]];

            if ([baseMapState objectForKey:@"tileSetURL"])
            {
                [tileOverlayState addObject:[baseMapState objectForKey:@"tileSetURL"]];
                [baseMapState removeObjectForKey:@"tileSetURL"];
            }
            
            // update to relative paths
            //
            for (int i = 0; i < [tileOverlayState count]; i++)
                if ([[tileOverlayState objectAtIndex:i] hasPrefix:@"/"] &&
                     ! [[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] isEqual:kDSOpenStreetMapURL] &&
                     ! [[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] isEqual:kDSMapQuestOSMURL])
                    [tileOverlayState replaceObjectAtIndex:i withObject:[[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] pathRelativeToApplicationSandbox]];

            for (int i = 0; i < [dataOverlayState count]; i++)
                if ([[dataOverlayState objectAtIndex:i] hasPrefix:@"/"])
                    [dataOverlayState replaceObjectAtIndex:i withObject:[[NSURL fileURLWithPath:[dataOverlayState objectAtIndex:i]] pathRelativeToApplicationSandbox]];

            // write back out
            //
            [defaults setObject:baseMapState     forKey:@"baseMapState"];
            [defaults setObject:tileOverlayState forKey:@"tileOverlayState"];
            [defaults setObject:dataOverlayState forKey:@"dataOverlayState"];
        }
        
        // saved docs
        //
        NSString *saveFolder = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDSSaveFolderName];
        
        NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:saveFolder]
                                                           includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLCreationDateKey, nil]
                                                                              options:0
                                                                                error:NULL];
        
        for (NSURL *saveFile in saveFiles)
        {
            // preserve timestamp because of doc ordering
            //
            NSString *path = [saveFile path];
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            
            baseMapState      = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"baseMapState"]];
            tileOverlayState  = [NSMutableArray arrayWithArray:[dict objectForKey:@"tileOverlayState"]];
            dataOverlayState  = [NSMutableArray arrayWithArray:[dict objectForKey:@"dataOverlayState"]];
            
            // move base to tile layers
            //
            if ([baseMapState objectForKey:@"tileSetURL"])
            {
                [tileOverlayState addObject:[baseMapState objectForKey:@"tileSetURL"]];
                [baseMapState removeObjectForKey:@"tileSetURL"];
            }
            
            // update to relative paths
            //
            for (int i = 0; i < [tileOverlayState count]; i++)
                if ([[tileOverlayState objectAtIndex:i] hasPrefix:@"/"] &&
                     ! [[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] isEqual:kDSOpenStreetMapURL] &&
                     ! [[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] isEqual:kDSMapQuestOSMURL])
                    [tileOverlayState replaceObjectAtIndex:i withObject:[[NSURL fileURLWithPath:[tileOverlayState objectAtIndex:i]] pathRelativeToApplicationSandbox]];
            
            for (int i = 0; i < [dataOverlayState count]; i++)
                if ([[dataOverlayState objectAtIndex:i] hasPrefix:@"/"])
                    [dataOverlayState replaceObjectAtIndex:i withObject:[[NSURL fileURLWithPath:[dataOverlayState objectAtIndex:i]] pathRelativeToApplicationSandbox]];
            
            // write back out
            //
            [dict setObject:baseMapState     forKey:@"baseMapState"];
            [dict setObject:tileOverlayState forKey:@"tileOverlayState"];
            [dict setObject:dataOverlayState forKey:@"dataOverlayState"];
            
            [dict writeToFile:path atomically:YES];
            
            [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:NULL];
        }
        
        // mark as done
        //
        [defaults setBool:YES forKey:@"legacyMigration1.5.x"];
        [defaults synchronize];
    }
}

@end