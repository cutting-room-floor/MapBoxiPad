//
//  UIApplication_Additions.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

void dispatch_delayed_ui_action(NSTimeInterval, dispatch_block_t block);

@interface UIApplication (UIApplication_Additions)

- (NSString *)documentsFolderPath;
- (NSString *)preferencesFolderPath;
- (NSString *)applicationSandboxFolderPath;

@end

#pragma mark -

@interface NSURL (UIApplication_Additions)

- (NSString *)pathRelativeToApplicationSandbox;

@end