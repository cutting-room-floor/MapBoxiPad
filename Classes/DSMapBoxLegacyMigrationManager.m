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
        
        for (NSString *saveFile in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:saveFolder error:NULL])
        {
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
        }
        
        // mark as done
        //
        [defaults setBool:YES forKey:@"legacyMigration1.3.x"];
        [defaults synchronize];
    }
}

@end