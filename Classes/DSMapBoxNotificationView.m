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

@synthesize message;

+ (id)notificationWithMessage:(NSString *)message
{
    DSMapBoxNotificationView *newView = [[[DSMapBoxNotificationView alloc] initWithFrame:CGRectMake(0, 44, 500, 30)] autorelease];
    
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
        
        label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 5, 480, 20)] autorelease];
        
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
    
    [[UIColor colorWithWhite:0.0 alpha:0.8] set];

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    
    CGContextAddPath(context, [path CGPath]);

    CGContextFillPath(context);
}

@end