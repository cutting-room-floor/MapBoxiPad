//
//  DSMapBoxLegendManager.m
//  MapBoxiPad
//
//  Created by Justin Miller on 11/9/11.
//  Copyright (c) 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLegendManager.h"

#import "DSMapBoxAlertView.h"

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"
#import "RMCachedTileSource.h"

#import "UIApplication_Additions.h"

#import "UIColor-Expanded.h"

#import <QuartzCore/QuartzCore.h>

#define kDSMapBoxLegendManagerAnimationDuration 0.25f

@interface CALayer (DSMapBoxLegendManager)

- (void)animateShadowOpacityTo:(CGFloat)opacity withDuration:(CFTimeInterval)duration;

@end

@implementation CALayer (DSMapBoxLegendManager)

- (void)animateShadowOpacityTo:(CGFloat)opacity withDuration:(CFTimeInterval)duration
{
    CABasicAnimation *shadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    
    [shadowOpacityAnimation setDuration:duration];
    [shadowOpacityAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [shadowOpacityAnimation setRemovedOnCompletion:NO];
    [shadowOpacityAnimation setFromValue:[NSNumber numberWithFloat:self.shadowOpacity]];
    [shadowOpacityAnimation setToValue:[NSNumber numberWithFloat:opacity]];
    
    [self addAnimation:shadowOpacityAnimation forKey:@"animateShadowOpacity"];
    
    self.shadowOpacity = opacity;
}

@end

#pragma mark -

@interface DSMapBoxLegendManager ()

@property (nonatomic, retain) IBOutlet UIView *legendView;
@property (nonatomic, retain) IBOutlet UIWebView *contentWebView;
@property (nonatomic, retain) IBOutlet UIImageView *dragHandle;
@property (nonatomic, retain) IBOutlet UIImageView *topScrollHint;
@property (nonatomic, retain) IBOutlet UIImageView *bottomScrollHint;
@property (nonatomic, assign) CGSize initialFrameSize;

- (void)handleGesture:(UIGestureRecognizer *)gesture;
- (void)collapseInterfaceAnimated:(BOOL)animated;
- (void)expandInterfaceAnimated:(BOOL)animated;
- (void)updateScrollHintsHiding:(BOOL)shouldHide;

@end

#pragma mark -

@implementation DSMapBoxLegendManager

@synthesize legendSources=_legendSources;
@synthesize legendView;
@synthesize contentWebView;
@synthesize dragHandle;
@synthesize topScrollHint;
@synthesize bottomScrollHint;
@synthesize initialFrameSize;

- (id)initWithFrame:(CGRect)frame parentView:(UIView *)parentView;
{
    self = [super init];
    
    if (self)
    {
        _legendSources = [[NSArray array] retain];

        // load UI
        //
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];

        // configure web view
        //
        contentWebView.scrollView.bounces                = YES;
        contentWebView.scrollView.alwaysBounceVertical   = YES;
        contentWebView.scrollView.alwaysBounceHorizontal = NO;
        
        contentWebView.scrollView.directionalLockEnabled = YES;
        contentWebView.scrollView.delegate = self;
        
        contentWebView.backgroundColor = [UIColor clearColor];
        contentWebView.opaque = NO;
        
        contentWebView.layer.shadowColor   = [[UIColor grayColor] CGColor];
        contentWebView.layer.shadowOffset  = CGSizeMake(0.0, 0.0);
        contentWebView.layer.shadowRadius  = 5.0;
        contentWebView.layer.shadowOpacity = 0.5;

        // remove web view scroller shadow image
        //
        for (UIView *shadowView in contentWebView.scrollView.subviews)
            if ([shadowView isKindOfClass:[UIImageView class]])
                [shadowView setHidden:YES];

        // custom shape mask on drag handle
        //
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        
        maskLayer.frame = dragHandle.bounds;
        maskLayer.path  = [[UIBezierPath bezierPathWithRoundedRect:dragHandle.bounds
                                                 byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight
                                                       cornerRadii:CGSizeMake(15.0, 15.0)] CGPath];
        
        dragHandle.layer.mask = maskLayer;
        
        [self updateScrollHintsHiding:YES];

        // setup initial legend size, hidden by default
        //
        initialFrameSize = frame.size;
        legendView.frame = frame;
        
        [parentView addSubview:legendView];
        
        legendView.hidden = YES;
        
        // attach hide & show gestures
        //
        UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [contentWebView addGestureRecognizer:leftSwipe];

        UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.dragHandle addGestureRecognizer:rightSwipe];
        
        UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        tap.numberOfTapsRequired = 1;
        [self.dragHandle addGestureRecognizer:tap];
        
        // start collapsed if left that way
        //
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"legendCollapsed"])
            [self collapseInterfaceAnimated:NO];
    }
    
    return self;
}

- (void)dealloc
{
    [_legendSources release];
    [legendView release];
    [contentWebView release];
    [dragHandle release];
    [topScrollHint release];
    [bottomScrollHint release];
    
    [super dealloc];
}

#pragma mark -

- (void)setLegendSources:(NSArray *)legendSources
{
    if ( ! [legendSources isEqualToArray:_legendSources])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // swap out new sources
        //
        [_legendSources release];
        _legendSources = [legendSources retain];
        
        // get TileMill CSS
        //
        NSString *controls = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"controls" ofType:@"css"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];

        NSString *reset    = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"reset" ofType:@"css"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];

        // determine legend content across sources (not every source will have a legend)
        //
        NSMutableArray *legends = [NSMutableArray array];
        
        for (id <RMTileSource>source in _legendSources)
            if ([source respondsToSelector:@selector(legend)] && [[source performSelector:@selector(legend)] length])
                [legends addObject:[source performSelector:@selector(legend)]];

        if ([legends count])
        {
            // reverse order (rightmost = topmost)
            //
            [legends setArray:[[legends reverseObjectEnumerator] allObjects]];
            
            // concatenate all legends together
            //
            NSString *legendContent = [NSString stringWithFormat:@"<div id='wax-legend' \
                                                                     class='wax-legend' \
                                                                     style='background-color: white; -webkit-tap-highlight-color: rgba(0,0,0,0);'> \
                                                                       %@ \
                                                                   </div> \
                                                                   <style type='text/css'> \
                                                                       %@ \
                                                                       %@ \
                                                                       .wax-legend { \
                                                                         max-height: 5000px; \
                                                                       } \
                                                                   </style>", [legends componentsJoinedByString:@""], controls, reset];
            
            // show UI if needed
            //
            self.legendView.hidden = NO;
            
            // move to just below app toolbar
            //
            for (UIView *parentSubview in self.legendView.superview.subviews)
            {
                if ([parentSubview isKindOfClass:[UIToolbar class]])
                {
                    UIView *superview = self.legendView.superview;
                    
                    [self.legendView removeFromSuperview];
                    
                    [superview insertSubview:self.legendView belowSubview:parentSubview];

                    break;
                }
            }
            
            // fade in
            //
            if (self.legendView.alpha < 1.0)
            {
                [UIView animateWithDuration:0.1
                                      delay:0.0
                                    options:UIViewAnimationCurveEaseOut
                                 animations:^(void)
                                 {
                                     self.legendView.alpha = 1.0;
                                 }
                                 completion:NULL];
            }
            
            // load the new content
            //
            [contentWebView loadHTMLString:legendContent baseURL:nil];
        }
        else
        {
            // otherwise, fade out the UI
            //
            [UIView animateWithDuration:0.1
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.alpha = 0.0;
                             }
                             completion:^(BOOL finished)
                             {
                                 self.legendView.hidden = YES;
                             }];
        }
    }
}

#pragma mark -

- (void)handleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]])
    {
        // left swipe main view or right swipe handle - collapse/expand
        //
        UISwipeGestureRecognizer *swipe = (UISwipeGestureRecognizer *)gesture;
        
        if (swipe.direction == UISwipeGestureRecognizerDirectionLeft)
        {
            [self collapseInterfaceAnimated:YES];
        }
        else if (swipe.direction == UISwipeGestureRecognizerDirectionRight)
        {
            [self expandInterfaceAnimated:YES];
        }
    }
    else if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        // handle tap - expand
        //
        [self expandInterfaceAnimated:YES];
    }
}

- (void)collapseInterfaceAnimated:(BOOL)animated
{
    self.dragHandle.hidden = NO;
    
    void (^movementBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x - self.contentWebView.frame.size.width - 5, 
                                             self.legendView.center.y);
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             movementBlock();
                         }
                         completion:NULL];
    }        
    else
    {
        movementBlock();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)expandInterfaceAnimated:(BOOL)animated
{
    self.dragHandle.hidden = YES;
    
    void (^movementBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x + self.contentWebView.frame.size.width + 5, 
                                             self.legendView.center.y);
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             movementBlock();
                         }
                         completion:NULL];
    }
    else
    {
        movementBlock();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateScrollHintsHiding:(BOOL)shouldHide
{
    CGFloat topTargetAlpha;
    CGFloat bottomTargetAlpha;
    
    if (self.contentWebView.scrollView.scrollEnabled)
    {
        if (shouldHide)
        {
            topTargetAlpha    = 0.0;
            bottomTargetAlpha = 0.0;
        }
        else
        {
            UIScrollView *scroller = self.contentWebView.scrollView;
            
            topTargetAlpha    = (scroller.contentOffset.y <= 0 ? 0.0 : 1.0);
            bottomTargetAlpha = (scroller.contentOffset.y + scroller.frame.size.height == scroller.contentSize.height ? 0.0 : 1.0);
        }
    }
    else
    {
        topTargetAlpha    = 0.0;
        bottomTargetAlpha = 0.0;
    }
    
    if (topTargetAlpha == 0.0)
        self.topScrollHint.alpha = topTargetAlpha;
    
    else
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseInOut
                         animations:^(void)
                         {
                             self.topScrollHint.alpha = topTargetAlpha;
                         }
                         completion:NULL];
    
    if (bottomTargetAlpha == 0.0)
        self.bottomScrollHint.alpha = bottomTargetAlpha;
    
    else
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseInOut
                         animations:^(void)
                         {
                             self.bottomScrollHint.alpha = bottomTargetAlpha;
                         }
                         completion:NULL];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // hide shadows when scrolling
    //
    [self.contentWebView.layer animateShadowOpacityTo:0.0 withDuration:kDSMapBoxLegendManagerAnimationDuration];
    [self updateScrollHintsHiding:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // bring shadows back when stationary
    //
    [self.contentWebView.layer animateShadowOpacityTo:0.5 withDuration:kDSMapBoxLegendManagerAnimationDuration];
    
    // if not bouncing, update hints
    //
    if ( ! decelerate)
        [self updateScrollHintsHiding:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // update hints after bouncing
    //
    [self updateScrollHintsHiding:NO];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ( ! [[request.URL absoluteString] isEqualToString:@"about:blank"])
    {
        DSMapBoxAlertView *alert = [[[DSMapBoxAlertView alloc] initWithTitle:@"Open URL?"
                                                                     message:[request.URL absoluteString]
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"Open", nil] autorelease];
        
        alert.context = request.URL;
        
        [alert show];
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // update legend container frame & scrolling status
    //
    CGFloat renderHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight"] floatValue] + 2;
    CGFloat renderWidth  = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientWidth"]  floatValue] + 2;    

    CGFloat newHeight = (renderHeight > initialFrameSize.height ? initialFrameSize.height : renderHeight);
    
    self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                       self.legendView.frame.origin.y + self.legendView.frame.size.height - newHeight,
                                       renderWidth + self.dragHandle.frame.size.width,
                                       newHeight);
    
    UIScrollView *scroller = self.contentWebView.scrollView;
    
    scroller.contentSize   = CGSizeMake(renderWidth, renderHeight);
    scroller.scrollEnabled = (self.contentWebView.scrollView.contentSize.height <= self.contentWebView.scrollView.frame.size.height ? NO : YES);

    [self updateScrollHintsHiding:NO];
    
    // theme link color
    //
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"links = document.getElementsByTagName('a'); \
                                                                                 for (i = 0; i < links.length; i++)          \
                                                                                     links[i].style.color = '#%@';", [kMapBoxBlue hexStringFromColor]]];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // confirmation for link taps to launch outside of app
    //
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [[UIApplication sharedApplication] openURL:((DSMapBoxAlertView *)alertView).context];
}

@end