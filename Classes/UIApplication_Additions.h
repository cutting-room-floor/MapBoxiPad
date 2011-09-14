//
//  UIApplication_Additions.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

void dispatch_delayed_ui_action(NSTimeInterval, dispatch_block_t block);

@interface UIApplication (UIApplication_Additions)

- (NSString *)documentsFolderPathString;
- (NSString *)preferencesFolderPathString;

@end