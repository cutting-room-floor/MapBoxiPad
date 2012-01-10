//
//  DSMapBoxDownloadTableViewCell.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadTableViewCell.h"

#import "SSPieProgressView.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxDownloadTableViewCell ()

@property (nonatomic, strong) IBOutlet SSPieProgressView *pie;
@property (nonatomic, strong) UIColor *originalPrimaryLabelTextColor;

@end

#pragma mark -

@implementation DSMapBoxDownloadTableViewCell

@synthesize primaryLabel;
@synthesize secondaryLabel;
@synthesize progress;
@synthesize isIndeterminate;
@synthesize isPaused;
@synthesize pie;
@synthesize originalPrimaryLabelTextColor;

- (void)awakeFromNib
{
    self.backgroundColor        = [UIColor whiteColor];
    
    self.pie.pieFillColor       = [UIColor colorWithCGColor:CGColorCreateCopyWithAlpha([kMapBoxBlue CGColor], 0.5)];
    self.pie.pieBackgroundColor = [UIColor clearColor];
    self.pie.pieBorderColor     = kMapBoxBlue;
 
    self.pie.pieBorderWidth     = 2.0;
    
    self.originalPrimaryLabelTextColor = self.primaryLabel.textColor;
}

#pragma mark -

- (void)setProgress:(CGFloat)newProgress
{
    if (self.isIndeterminate && newProgress < 1.0)
        return;
    
    self.pie.progress = newProgress;
}

- (CGFloat)progress
{
    if (self.isIndeterminate && self.pie.progress < 1.0)
        return 0.0;
    
    return self.pie.progress;
}

- (void)setIsIndeterminate:(BOOL)flag
{
    if (flag == isIndeterminate)
        return;
    
    isIndeterminate = flag;
    
    if (flag)
    {
        self.pie.progress = 1.0;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationRepeatAutoreverses:YES];
        [UIView setAnimationRepeatCount:MAXFLOAT];
        [UIView setAnimationDuration:1.0];
        
        self.pie.alpha = 0.5;
        
        [UIView commitAnimations];
    }
}

- (void)setIsPaused:(BOOL)flag
{
    if (flag == isPaused)
        return;
    
    isPaused = flag;
    
    if (flag)
    {
        // dim primary label
        //
        self.primaryLabel.textColor = self.secondaryLabel.textColor;
        
        // hide the animated pie
        //
        self.pie.hidden = YES;
        
        // draw a pulsing, empty, dimmed pie
        //
        CGSize pieSize = self.pie.bounds.size;
        
        UIGraphicsBeginImageContext(pieSize);
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        [self.secondaryLabel.textColor setStroke];
        
        CGContextSetLineWidth(c, self.pie.pieBorderWidth);
        
        CGContextStrokeEllipseInRect(c, CGRectMake(self.pie.pieBorderWidth / 2, self.pie.pieBorderWidth / 2, pieSize.width - self.pie.pieBorderWidth, pieSize.height - self.pie.pieBorderWidth));
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        UIView *pulseView = [[UIView alloc] initWithFrame:self.pie.frame];
        
        pulseView.layer.contents = (id)[image CGImage];
        
        [self.pie.superview insertSubview:pulseView aboveSubview:self.pie];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationRepeatAutoreverses:YES];
        [UIView setAnimationRepeatCount:MAXFLOAT];
        [UIView setAnimationDuration:1.0];
        
        pulseView.alpha = 0.2;
        
        [UIView commitAnimations];
    }
    else
    {
        // revert primary label
        //
        self.primaryLabel.textColor = self.originalPrimaryLabelTextColor;
        
        // remove pulsing view
        //
        [[self.pie.superview.subviews lastObject] removeFromSuperview];
        
        // fade in pie view
        //
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:1.0];
        
        self.pie.hidden = NO;
        
        [UIView commitAnimations];
    }
}

@end