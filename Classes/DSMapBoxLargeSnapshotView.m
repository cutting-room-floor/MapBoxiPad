//
//  DSMapBoxLargeSnapshotView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLargeSnapshotView.h"

#import <QuartzCore/QuartzCore.h>

#define kDSSnapshotInset kDSDocumentWidth / 32.0f
#define kDimmerAlpha     0.5f

@implementation DSMapBoxLargeSnapshotView

@synthesize snapshotName;
@synthesize delegate;
@synthesize isActive;

- (id)initWithSnapshot:(UIImage *)snapshot
{
    self = [super initWithFrame:CGRectMake(0, 0, kDSDocumentWidth, kDSDocumentHeight)];
    
    if (self != nil)
    {
        // setup image view
        //
        UIImageView *imageView = [[UIImageView alloc] initWithImage:snapshot];
        
        [self addSubview:imageView];

        CGFloat width;
        CGFloat height;
        
        if (snapshot.size.width > snapshot.size.height)
        {
            width  = kDSDocumentWidth;
            height = kDSDocumentHeight;
        }
        else
        {
            width  = kDSDocumentHeight;
            height = kDSDocumentHeight;
        }
        
        imageView.frame = CGRectMake(kDSSnapshotInset, 
                                     kDSSnapshotInset, 
                                     width  - kDSSnapshotInset * 2, 
                                     height - kDSSnapshotInset * 2);

        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.center      = self.center;
        
        // determine actual fit image size
        //
        if (snapshot.size.width > snapshot.size.height)
        {
            width  = imageView.frame.size.width;
            height = imageView.frame.size.width * (snapshot.size.height / snapshot.size.width);
        }
        else
        {
            width  = imageView.frame.size.height * (snapshot.size.width / snapshot.size.height);
            height = imageView.frame.size.height;
        }
        
        // setup dimming overlay
        //
        UIView *dimmer = [[UIView alloc] initWithFrame:CGRectZero];
        
        dimmer.frame = CGRectMake(0,
                                  0, 
                                  width,
                                  height);
        
        dimmer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kDimmerAlpha];

        [self insertSubview:dimmer aboveSubview:imageView];

        dimmer.center = imageView.center;

        // add shadow, but only on image
        //
        CGSize shadowOffset;
        
        if (width > height)
            shadowOffset = CGSizeMake(0, (imageView.bounds.size.height - height) / 2 + 3);

        else
            shadowOffset = CGSizeMake((imageView.bounds.size.width - width) / 2, 3);
        
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset  = shadowOffset;
        imageView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:dimmer.bounds] CGPath];
    }
    
    return self;
}

#pragma mark -

- (void)setIsActive:(BOOL)flag
{
    isActive = flag;
    
    UIView *dimmer = (UIView *)[[self subviews] lastObject];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    
    if (flag)
        dimmer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    else
        dimmer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:kDimmerAlpha];
    
    [UIView commitAnimations];
}

#pragma mark -

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(snapshotViewWasTapped:withName:)])
        [self.delegate snapshotViewWasTapped:self withName:snapshotName];
}

@end