//
//  UIApplication_Additions.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "UIApplication_Additions.h"

#import <BlocksKit/BlocksKit.h>

static const char *UIApplication_Additions_documentsFolderPathKey          = "UIApplication_Additions_documentsFolderPathKey";
static const char *UIApplication_Additions_preferencesFolderPathKey        = "UIApplication_Additions_preferencesFolderPathKey";
static const char *UIApplication_Additions_applicationSandboxFolderPathKey = "UIApplication_Additions_applicationSandboxFolderPathKey";

void dispatch_delayed_ui_action(NSTimeInterval delaySeconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC), dispatch_get_main_queue(), block);
}

@implementation UIApplication (UIApplication_Additions)

- (NSString *)documentsFolderPath
{
    if ( ! [self associatedValueForKey:UIApplication_Additions_documentsFolderPathKey])
    {
        NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        [self associateValue:[userPaths objectAtIndex:0] withKey:UIApplication_Additions_documentsFolderPathKey];
    }
    
    return [self associatedValueForKey:UIApplication_Additions_documentsFolderPathKey];
}

- (NSString *)preferencesFolderPath
{
    if ( ! [self associatedValueForKey:UIApplication_Additions_preferencesFolderPathKey])
    {
        NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        
        [self associateValue:[NSString stringWithFormat:@"%@/Preferences", [userPaths objectAtIndex:0]] withKey:UIApplication_Additions_preferencesFolderPathKey];
    }
    
    return [self associatedValueForKey:UIApplication_Additions_preferencesFolderPathKey];
}

- (NSString *)applicationSandboxFolderPath
{
    if ( ! [self associatedValueForKey:UIApplication_Additions_applicationSandboxFolderPathKey])
    {
        NSMutableArray *parts = [NSMutableArray arrayWithArray:[[[NSBundle mainBundle] bundleURL] pathComponents]];

        [parts removeObject:@"/"];
        [parts removeLastObject];
        
        [self associateValue:[@"/" stringByAppendingString:[parts componentsJoinedByString:@"/"]] withKey:UIApplication_Additions_applicationSandboxFolderPathKey];
    }
    
    return [self associatedValueForKey:UIApplication_Additions_applicationSandboxFolderPathKey];
}

@end

#pragma mark -

@implementation NSURL (UIApplication_Additions)

- (NSString *)pathRelativeToApplicationSandbox;
{
    /**
     * This exists so that paths can be stored relative to the app sandbox
     * in case that absolute sandbox path changes. This could happen when the 
     * app is reinstalled or when testing in the simulator. 
     */

    if ([self isEqual:kDSOpenStreetMapURL] || [self isEqual:kDSMapQuestOSMURL])
        return [self relativePath];
    
    NSURL *sandboxURL = [[NSBundle mainBundle] bundleURL];
    
    int count = [[sandboxURL pathComponents] count] - 1;
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[self pathComponents]];
    
    [parts removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
    
    return [parts componentsJoinedByString:@"/"];
}

@end