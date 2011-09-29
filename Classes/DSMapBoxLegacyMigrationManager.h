//
//  DSMapBoxLegacyMigrationManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/19/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@interface DSMapBoxLegacyMigrationManager : NSObject
{
}

+ (DSMapBoxLegacyMigrationManager *)defaultManager;

- (void)migrate;

@end