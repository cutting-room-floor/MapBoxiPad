//
//  UIApplication_Additions.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "UIApplication_Additions.h"

void dispatch_delayed_ui_action(NSTimeInterval delaySeconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC), dispatch_get_main_queue(), block);
}

@implementation UIApplication (UIApplication_Additions)

- (NSString *)documentsFolderPath
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [userPaths objectAtIndex:0];
}

- (NSString *)preferencesFolderPath
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    return [NSString stringWithFormat:@"%@/Preferences", [userPaths objectAtIndex:0]];
}

- (NSString *)applicationSandboxFolderPath
{
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[[[NSBundle mainBundle] bundleURL] pathComponents]];

    [parts removeObject:@"/"];
    [parts removeLastObject];
    
    return [@"/" stringByAppendingString:[parts componentsJoinedByString:@"/"]];
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