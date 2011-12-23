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

@property (nonatomic, strong) IBOutlet UIView *legendView;
@property (nonatomic, strong) IBOutlet UIWebView *contentWebView;
@property (nonatomic, strong) IBOutlet UIImageView *dragHandle;
@property (nonatomic, strong) IBOutlet UIImageView *topScrollHint;
@property (nonatomic, strong) IBOutlet UIImageView *bottomScrollHint;

- (void)handleGesture:(UIGestureRecognizer *)gesture;
- (void)collapseInterfaceAnimated:(BOOL)animated;
- (void)expandInterfaceAnimated:(BOOL)animated;
- (void)updateScrollHints;

@end

#pragma mark -

@implementation DSMapBoxLegendManager

@synthesize legendSources=_legendSources;
@synthesize legendView;
@synthesize contentWebView;
@synthesize dragHandle;
@synthesize topScrollHint;
@synthesize bottomScrollHint;

- (id)initWithFrame:(CGRect)frame parentView:(UIView *)parentView;
{
    self = [super init];
    
    if (self)
    {
        _legendSources = [NSArray array];

        // load UI
        //
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];

        // configure web view & scroller
        //
        contentWebView.scrollView.bounces                = YES;
        contentWebView.scrollView.alwaysBounceVertical   = YES;
        contentWebView.scrollView.alwaysBounceHorizontal = NO;
        
        contentWebView.scrollView.directionalLockEnabled = YES;
        contentWebView.scrollView.delegate = self;
        
        contentWebView.backgroundColor = [UIColor clearColor];
        contentWebView.opaque = NO;
        
        contentWebView.layer.shadowColor   = [[UIColor blackColor] CGColor];
        contentWebView.layer.shadowOffset  = CGSizeMake(0.0, 0.0);
        contentWebView.layer.shadowRadius  = 5.0;
        contentWebView.layer.shadowOpacity = 1.0;

        // remove web view scroller background shadow image
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
        
        // hide by default
        //
        dragHandle.layer.transform = CATransform3DMakeTranslation(-dragHandle.bounds.size.width, 0.0, 0.0);

        [self updateScrollHints];

        // setup initial legend size, hidden by default
        //
        legendView.frame = frame;
        
        [parentView addSubview:legendView];
        
        legendView.hidden = YES;
        
        // attach hide & show gestures
        //
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [contentWebView addGestureRecognizer:leftSwipe];

        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.dragHandle addGestureRecognizer:rightSwipe];
        [self.legendView addGestureRecognizer:rightSwipe];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        tap.numberOfTapsRequired = 1;
        [self.dragHandle addGestureRecognizer:tap];
        
        // start collapsed if left that way
        //
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"legendCollapsed"])
            [self collapseInterfaceAnimated:NO];
    }
    
    return self;
}

#pragma mark -

- (void)setLegendSources:(NSArray *)legendSources
{
    if ( ! [legendSources isEqualToArray:_legendSources])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // swap out new sources
        //
        _legendSources = legendSources;
        
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
                                                                         max-width:   300px; \
                                                                       } \
                                                                   </style>", [legends componentsJoinedByString:@""], controls, reset];
            
            // prepare to show UI if needed
            //
            if (self.legendView.hidden)
            {
                self.legendView.alpha  = 0.0;
                self.legendView.hidden = NO;
            }
            
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
            
            // load the new content
            //
            [contentWebView loadHTMLString:legendContent baseURL:nil];
        }
        else
        {
            // otherwise, fade out the UI
            //
            [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
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
        // left swipe main view or right swipe handle or trough - collapse/expand
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
    // enable trough swipe
    //
    [[self.legendView.gestureRecognizers lastObject] setEnabled:YES];
    
    self.dragHandle.hidden = NO;
    
    void (^collapse)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x - self.contentWebView.frame.size.width - 5, 
                                             self.legendView.center.y);
        
        [self.contentWebView.layer animateShadowOpacityTo:0.0 withDuration:kDSMapBoxLegendManagerAnimationDuration];
        
        self.dragHandle.layer.transform = CATransform3DTranslate(self.dragHandle.layer.transform, self.dragHandle.bounds.size.width, 0.0, 0.0);
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             collapse();
                         }
                         completion:NULL];
    }        
    else
    {
        collapse();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)expandInterfaceAnimated:(BOOL)animated
{
    // disable trough swipe
    //
    [[self.legendView.gestureRecognizers lastObject] setEnabled:NO];
    
    void (^expand)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x + self.contentWebView.frame.size.width + 5, 
                                             self.legendView.center.y);
        
        [self.contentWebView.layer animateShadowOpacityTo:1.0 withDuration:kDSMapBoxLegendManagerAnimationDuration];
        
        self.dragHandle.layer.transform = CATransform3DTranslate(self.dragHandle.layer.transform, -self.dragHandle.bounds.size.width, 0.0, 0.0);
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             expand();
                         }
                         completion:^(BOOL finished)
                         {
                             self.dragHandle.hidden = YES;
                         }];
    }
    else
    {
        expand();
        self.dragHandle.hidden = YES;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateScrollHints
{
    CGFloat topTargetAlpha;
    CGFloat bottomTargetAlpha;
    
    if (self.contentWebView.scrollView.scrollEnabled)
    {
        UIScrollView *scroller = self.contentWebView.scrollView;
        
        topTargetAlpha    = (scroller.contentOffset.y <= 0 ? 0.0 : 1.0);
        bottomTargetAlpha = (scroller.contentOffset.y + scroller.frame.size.height >= scroller.contentSize.height ? 0.0 : 1.0);
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
    [self updateScrollHints];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // if not bouncing, bring shadows back
    //
    if ( ! decelerate)
        [self updateScrollHints];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // bring back shadows after bouncing
    //
    [self updateScrollHints];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ( ! [[request.URL absoluteString] isEqualToString:@"about:blank"] && navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        DSMapBoxAlertView *alert = [[DSMapBoxAlertView alloc] initWithTitle:@"Open URL?"
                                                                    message:[request.URL absoluteString]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Open", nil];
        
        alert.context = request.URL;
        
        [alert show];
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // prepare fade-in animation
    //
    void (^fadeIn)(void) = ^
    {
        if (self.legendView.alpha < 1.0)
        {
            [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.alpha = 1.0;
                             }
                             completion:NULL];
        }
    };
    
    // determine render height of new content
    //
    CGFloat h = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight"] floatValue] + 2;

    // clamp to max legend height
    //
    CGFloat newHeight = (h > kDSMapBoxLegendManagerMaxHeight ? kDSMapBoxLegendManagerMaxHeight : h);
    
    // determine if we're growing or shrinking in size
    //
    CGFloat heightDelta = self.legendView.frame.size.height - newHeight;
    
    if (heightDelta != 0)
    {
        void (^move)(void) = ^
        {
            self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                               self.legendView.frame.origin.y + heightDelta,
                                               self.legendView.frame.size.width,
                                               self.legendView.frame.size.height);
        };
        
        void (^resize)(void) = ^
        {
            self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                               self.legendView.frame.origin.y,
                                               self.legendView.frame.size.width,
                                               newHeight);
        };
        
        if (heightDelta > 0)
        {
            // shrinking - move down, then resize
            //
            [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                                  delay:0.0
                                options:UIViewAnimationCurveEaseInOut
                             animations:^(void)
                             {
                                 move();
                                 resize();
                             }
                             completion:^(BOOL finished)
                             {
                                 fadeIn();
                             }];
        }
        else
        {
            // growing - resize, then move up
            //
            [UIView animateWithDuration:kDSMapBoxLegendManagerAnimationDuration
                                  delay:0.0
                                options:UIViewAnimationCurveEaseInOut
                             animations:^(void)
                             {
                                 resize();
                                 move();
                             }
                             completion:^(BOOL finished)
                             {
                                 fadeIn();
                             }];
        }
    }
    else
    {
        fadeIn();
    }
    
    // update scroll behavior
    //
    self.contentWebView.scrollView.contentSize   = CGSizeMake(self.contentWebView.scrollView.frame.size.width, h);
    self.contentWebView.scrollView.scrollEnabled = (self.contentWebView.scrollView.contentSize.height <= self.contentWebView.scrollView.frame.size.height ? NO : YES);

    [self updateScrollHints];
    
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