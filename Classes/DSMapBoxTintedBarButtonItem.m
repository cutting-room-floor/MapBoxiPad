//
//  DSMapBoxTintedBarButtonItem.m
//  MapBoxiPad
//
//  Created by Justin Miller on 6/30/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxTintedBarButtonItem.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxTintedBarButtonItem ()

- (void)setTitleResizing:(NSString *)title;

@property (nonatomic, retain) UIButton *tintedButton;

@end

#pragma mark -

@implementation DSMapBoxTintedBarButtonItem

@synthesize tintedButton;

- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    // setup UIButton with custom image
    //
    tintedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [tintedButton setBackgroundImage:[UIImage imageNamed:@"mapbox_button.png"] forState:UIControlStateNormal];

    tintedButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
    
    [tintedButton.layer setCornerRadius:4.0];
    [tintedButton.layer setMasksToBounds:YES];
    [tintedButton.layer setBorderWidth:1.0];
    [tintedButton.layer setBorderColor:[[UIColor blackColor] CGColor]];

    [tintedButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    [tintedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [tintedButton setTitleColor:[UIColor grayColor]  forState:UIControlStateDisabled];
    
    [tintedButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self setTitleResizing:title];
    
    // set it as custom view
    //
    self = [super initWithCustomView:tintedButton];
    
    return self;
}

#pragma mark -

- (void)setTitle:(NSString *)title
{
    [self setTitleResizing:title];
}

#pragma mark -

- (void)setTitleResizing:(NSString *)title
{
    [self.tintedButton setTitle:title forState:UIControlStateNormal];
    
    CGSize textSize = [title sizeWithFont:self.tintedButton.titleLabel.font];
    
    self.tintedButton.bounds = CGRectMake(0, 0, textSize.width + 22, textSize.height + 15);
}

@end