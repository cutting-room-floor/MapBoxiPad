//
//  DSMapBoxNotificationCenter.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/2/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxNotificationCenter.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxNotificationCenter ()

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UILabel *label;

- (id)initWithFrame:(CGRect)rect;

@end

#pragma mark -

@implementation DSMapBoxNotificationCenter

@synthesize view;
@synthesize label;

+ (DSMapBoxNotificationCenter *)sharedInstance
{
    static dispatch_once_t token;
    static DSMapBoxNotificationCenter *sharedInstance = nil;
    
    dispatch_once(&token, ^{ sharedInstance = [[self alloc] initWithFrame:CGRectMake(0, 44, 500, 30)]; });  
    
    return sharedInstance;
}

#pragma mark -

- (id)initWithFrame:(CGRect)rect
{
    self = [super init];

    if (self != nil)
    {
        view = [[UIView alloc] initWithFrame:rect];
        
        view.backgroundColor        = [UIColor colorWithWhite:0.0 alpha:0.6];
        view.userInteractionEnabled = NO;

        view.layer.shadowOffset     = CGSizeMake(0, 1);
        view.layer.shadowOpacity    = 0.2;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 480, 20)];
        
        label.textColor        = [UIColor whiteColor];
        label.backgroundColor  = [UIColor clearColor];
        label.shadowColor      = [UIColor blackColor];
        label.shadowOffset     = CGSizeMake(0, 1);
        label.font             = [UIFont systemFontOfSize:13.0];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [view addSubview:label];
        
        [[((UIWindow *)[[[UIApplication sharedApplication] windows] objectAtIndex:0]).subviews objectAtIndex:0] addSubview:view];
    }
    
    return self;
}

#pragma mark -

- (void)notifyWithMessage:(NSString *)message
{
    // hide first
    //
    self.view.alpha = 0.0;
    
    // update label
    //
    self.label.text = message;
    
    // resize as needed
    //
    CGSize labelSize   = self.label.frame.size;
    CGSize textSize    = [self.label.text sizeWithFont:self.label.font];
    
    CGFloat adjustment = labelSize.width - textSize.width;
    
    self.view.frame = CGRectMake(self.view.frame.origin.x,  
                                 self.view.frame.origin.y, 
                                 self.view.frame.size.width - adjustment, 
                                 self.view.frame.size.height);
    
    // animate in & out
    //
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationCurveEaseIn
                     animations:^(void)
                     {
                         self.view.alpha = 1.0;
                     }
                     completion:^(BOOL finished)
                     {
                         [UIView animateWithDuration:0.5
                                               delay:3.0
                                             options:UIViewAnimationCurveEaseOut
                                          animations:^(void)
                                          {
                                              self.view.alpha = 0.0;
                                          }
                                          completion:nil];
                     }];
}

@end