//
//  UIAlertView_Additions.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/10/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const UIAlertViewAdditionsContext;

@interface UIAlertView (UIAlertView_Additions)

- (void)setContext:(id)context;
- (id)context;

@end