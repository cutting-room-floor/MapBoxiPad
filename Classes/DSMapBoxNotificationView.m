//
//  DSMapBoxNotificationView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/2/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxNotificationView.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxNotificationView

static DSMapBoxNotificationView *notificationView;

@synthesize message;

+ (id)notificationWithMessage:(NSString *)message
{
    @synchronized(@"DSMapBoxNotificationView")
    {
        if ( ! notificationView)
        {
            notificationView = [[DSMapBoxNotificationView alloc] initWithFrame:CGRectMake(0, 44, 500, 30)];
            
            notificationView.message = message;
            
            [[((UIWindow *)[[[UIApplication sharedApplication] windows] objectAtIndex:0]).subviews objectAtIndex:0] addSubview:notificationView];
            
            notificationView.alpha = 0.0;
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationCurveEaseIn
                             animations:^(void)
                             {
                                 notificationView.alpha = 1.0;
                             }
                             completion:^(BOOL finished)
                             {
                                 [UIView animateWithDuration:0.5
                                                       delay:3.0
                                                     options:UIViewAnimationCurveEaseOut
                                                  animations:^(void)
                                                  {
                                                      notificationView.alpha = 0.0;
                                                  }
                                                  completion:^(BOOL finished)
                                                  {
                                                      [notificationView removeFromSuperview];
                                                      [notificationView release];
                                                      notificationView = nil;
                                                  }];
                             }];
        }
    }
    
    return notificationView;
}

#pragma mark -

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];

    if (self != nil)
    {
        self.backgroundColor        = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        self.layer.shadowOffset     = CGSizeMake(0, 1);
        self.layer.shadowOpacity    = 0.2;
        
        label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 4, 480, 20)] autorelease];
        
        label.textColor        = [UIColor whiteColor];
        label.backgroundColor  = [UIColor clearColor];
        label.shadowColor      = [UIColor blackColor];
        label.shadowOffset     = CGSizeMake(0, 1);
        label.font             = [UIFont systemFontOfSize:13.0];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [self addSubview:label];        
    }
    
    return self;
}

#pragma mark -

- (void)setMessage:(NSString *)inMessage
{
    // swap it out
    //
    [message release];
    message = [inMessage retain];
    
    // update label
    //
    label.text = message;
    
    // resize as needed
    //
    CGSize labelSize   = label.frame.size;
    CGSize textSize    = [label.text sizeWithFont:label.font];
    
    CGFloat adjustment = labelSize.width - textSize.width;
    
    self.frame = CGRectMake(self.frame.origin.x,  self.frame.origin.y, self.frame.size.width - adjustment, self.frame.size.height);
}

#pragma mark -

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor colorWithWhite:0.0 alpha:0.6] set];

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    
    CGContextAddPath(context, [path CGPath]);

    CGContextFillPath(context);
}

@end