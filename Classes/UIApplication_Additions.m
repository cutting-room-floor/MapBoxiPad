//
//  UIApplication_Additions.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "UIApplication_Additions.h"

void dispatch_delayed_ui_action(NSTimeInterval delaySeconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC), dispatch_get_main_queue(), block);
}

@implementation UIApplication (UIApplication_Additions)

- (NSString *)documentsFolderPathString
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [userPaths objectAtIndex:0];
}

- (NSString *)preferencesFolderPathString
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    return [NSString stringWithFormat:@"%@/Preferences", [userPaths objectAtIndex:0]];
}

@end