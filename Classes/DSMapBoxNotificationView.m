//
//  DSMapBoxNotificationView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/2/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxNotificationView.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxNotificationView ()

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) UILabel *label;

@end

#pragma mark -

@implementation DSMapBoxNotificationView

@synthesize message;
@synthesize label;

+ (DSMapBoxNotificationView *)notificationWithMessage:(NSString *)message
{
    DSMapBoxNotificationView *newView = [[self alloc] initWithFrame:CGRectMake(0, 44, 500, 30)];
    
    newView.message = message;
    
    return newView;
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
        self.layer.shadowOpacity    = 0.5;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 480, 20)];
        
        label.textColor        = [UIColor whiteColor];
        label.backgroundColor  = [UIColor clearColor];
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
    message = inMessage;
    
    // update label
    //
    self.label.text = message;
    
    // resize as needed
    //
    CGSize labelSize   = self.label.frame.size;
    CGSize textSize    = [self.label.text sizeWithFont:self.label.font];
    
    CGFloat adjustment = labelSize.width - textSize.width;
    
    self.frame = CGRectMake(self.frame.origin.x,  self.frame.origin.y, self.frame.size.width - adjustment, self.frame.size.height);
}

#pragma mark -

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor colorWithWhite:0.0 alpha:0.8] set];

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    
    CGContextAddPath(context, [path CGPath]);

    CGContextFillPath(context);
}

@end