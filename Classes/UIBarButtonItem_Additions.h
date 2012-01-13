//
//  UIBarButtonItem_Additions.h
//  MapBoxiPad
//
//  Created by Justin Miller on 1/13/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import <BlocksKit/BlocksKit.h>

@interface UIBarButtonItem (UIBarButtonItem_Additions)

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action tintColor:(UIColor *)tintColor;
- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action tintColor:(UIColor *)tintColor;
- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style handler:(BKSenderBlock)action tintColor:(UIColor *)tintColor;

@end