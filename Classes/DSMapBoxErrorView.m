//
//  DSMapBoxErrorView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/13/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxErrorView.h"

#define DSMapBoxErrorViewWidth  400.0f
#define DSMapBoxErrorViewHeight 150.0f
#define DSMapBoxErrorViewAlpha    0.8f

@interface DSMapBoxErrorView ()

- (void)DSMapBoxErrorView_commonInit;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSString *message;

@end

#pragma mark -

@implementation DSMapBoxErrorView

@synthesize imageView;
@synthesize textField;
@synthesize message;

+ (DSMapBoxErrorView *)errorViewWithMessage:(NSString *)inMessage
{
    return [[self alloc] initWithMessage:inMessage];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if (self)
        [self DSMapBoxErrorView_commonInit];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, DSMapBoxErrorViewWidth, DSMapBoxErrorViewHeight)];
    
    if (self)
        [self DSMapBoxErrorView_commonInit];
    
    return self;
}

- (id)initWithMessage:(NSString *)inMessage
{
    self = [super initWithFrame:CGRectMake(0, 0, DSMapBoxErrorViewWidth, DSMapBoxErrorViewHeight)];

    if (self)
        [self DSMapBoxErrorView_commonInit];
    
    self.message = inMessage;
    
    return self;
}

- (void)DSMapBoxErrorView_commonInit
{
    self.backgroundColor = [UIColor clearColor];
    
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
    
    imageView.frame = CGRectMake((DSMapBoxErrorViewWidth - imageView.bounds.size.width) / 2, 0, imageView.bounds.size.width, imageView.bounds.size.height);
    imageView.alpha = DSMapBoxErrorViewAlpha;
    
    [self addSubview:imageView];
    
    textField = [[UITextField alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 20, self.bounds.size.width, 20)];
    
    textField.textColor                 = [UIColor whiteColor];
    textField.backgroundColor           = [UIColor clearColor];
    textField.textAlignment             = UITextAlignmentCenter;
    textField.text                      = @"Error";
    textField.font                      = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
    textField.adjustsFontSizeToFitWidth = NO;
    
    [self addSubview:textField];
}

#pragma mark -

- (void)setMessage:(NSString *)inMessage
{
    self.textField.text = inMessage;
}

#pragma mark -

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    self.alpha = 0.0;
}

- (void)didMoveToSuperview
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    
    self.alpha = 1.0;
    
    [UIView commitAnimations];
}

@end