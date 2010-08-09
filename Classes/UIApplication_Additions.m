//
//  UIApplication_Additions.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "UIApplication_Additions.h"

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