//
//  UIBarButtonItem_Additions.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/13/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "UIBarButtonItem_Additions.h"

@implementation UIBarButtonItem (UIBarButtonItem_Additions)

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action tintColor:(UIColor *)tintColor
{
    self = [self initWithBarButtonSystemItem:systemItem target:target action:action];
    
    if (self)
        self.tintColor = tintColor;
    
    return self;
}

- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action tintColor:(UIColor *)tintColor
{
    self = [self initWithTitle:title style:style target:target action:action];
    
    if (self)
        self.tintColor = tintColor;
    
    return self;
}

- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style handler:(BKSenderBlock)action tintColor:(UIColor *)tintColor
{
    self = [self initWithTitle:title style:style handler:action];
    
    if (self)
        self.tintColor = tintColor;
    
    return self;
}

@end