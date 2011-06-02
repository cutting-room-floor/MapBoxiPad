//
//  DSMapBoxLegacyMigrationManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/19/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSMapBoxLegacyMigrationManager : NSObject
{
}

+ (DSMapBoxLegacyMigrationManager *)defaultManager;

- (void)migrate;

@end