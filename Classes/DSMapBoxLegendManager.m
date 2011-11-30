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

#import "StyledPageControl.h"

#import "UIColor-Expanded.h"

#import <QuartzCore/QuartzCore.h>

#define kDSMapBoxLegendManagerHideShowDuration       0.25f
#define kDSMapBoxLegendManagerCollapseExpandDuration 0.25f
#define kDSMapBoxLegendManagerPostInteractionDelay   2.0f

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
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIScrollView *scroller;
@property (nonatomic, retain) IBOutlet StyledPageControl *pager;
@property (nonatomic, retain) IBOutlet UIImageView *dragHandle;
@property (nonatomic, assign) CGFloat initialHeight;

- (void)handleGesture:(UIGestureRecognizer *)gesture;
- (void)showInterface;
- (void)hideInterface;
- (void)collapseInterfaceAnimated:(BOOL)animated;
- (void)expandInterfaceAnimated:(BOOL)animated;

@end

#pragma mark -

@implementation DSMapBoxLegendManager

@synthesize legendSources=_legendSources;
@synthesize legendView;
@synthesize backgroundView;
@synthesize label;
@synthesize scroller;
@synthesize pager;
@synthesize dragHandle;
@synthesize initialHeight;

- (id)initWithView:(UIView *)view
{
    self = [super init];
    
    if (self)
    {
        _legendSources = [[NSArray array] retain];

        // load UI & pretty it up
        //
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];

        initialHeight = legendView.frame.size.height;
        
        dragHandle.layer.borderColor  = [[UIColor colorWithWhite:0.5 alpha:0.25] CGColor];
        dragHandle.layer.borderWidth  = 1.0;

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        
        maskLayer.frame = dragHandle.bounds;
        maskLayer.path  = [[UIBezierPath bezierPathWithRoundedRect:dragHandle.bounds
                                                 byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight
                                                       cornerRadii:CGSizeMake(15.0, 15.0)] CGPath];
        
        dragHandle.layer.mask = maskLayer;
        
        label.layer.borderColor = [[UIColor blackColor] CGColor];
        label.layer.borderWidth = 1.0;
        
        // make an L-shaped shadow on the (transparent) edges of the main background
        //
        UIGraphicsBeginImageContext(CGSizeMake(backgroundView.bounds.size.width, backgroundView.bounds.size.height));
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        CGContextMoveToPoint(c, 0, 0);
        CGContextAddLineToPoint(c, backgroundView.bounds.size.width, 0);
        CGContextAddLineToPoint(c, backgroundView.bounds.size.width, backgroundView.bounds.size.height);
        CGContextAddLineToPoint(c, backgroundView.bounds.size.width - 5, backgroundView.bounds.size.height);
        CGContextAddLineToPoint(c, backgroundView.bounds.size.width - 5, 5);
        CGContextAddLineToPoint(c, 0, 5);
        CGContextClosePath(c);
        
        CGPathRef shadowPath = CGContextCopyPath(c);
        
        UIGraphicsEndImageContext();
        
        backgroundView.layer.shadowPath    = shadowPath;
        backgroundView.layer.shadowColor   = [[UIColor blackColor] CGColor];
        backgroundView.layer.shadowOpacity = 1.0;
        backgroundView.layer.shadowRadius  = 10.0;
        backgroundView.layer.shadowOffset  = CGSizeMake(3.0, -3.0);
        
        // swap in programmatic pager for unloadable XIB one
        //
        StyledPageControl *newPager = [[[StyledPageControl alloc] initWithFrame:pager.frame] autorelease];

        [pager removeFromSuperview];
        [legendView addSubview:newPager];
        
        [pager release];
        pager = [newPager retain];
        
        pager.hidesForSinglePage = YES;
        
        pager.backgroundColor = label.backgroundColor;
        
        pager.pageControlStyle = PageControlStyleDefault;

        pager.diameter = 10.0;
        
        pager.coreNormalColor   = [UIColor colorWithWhite:0.5 alpha:0.5];
        pager.coreSelectedColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        
        pager.gestureRecognizers = nil;
        
        pager.layer.borderColor = [[UIColor blackColor] CGColor];
        pager.layer.borderWidth = 1.0;
        
        // start with legend in lower-left, hidden by default
        //
        legendView.frame = CGRectMake(view.frame.origin.x, 
                                      view.frame.size.height - legendView.frame.size.height, 
                                      legendView.frame.size.width, 
                                      legendView.frame.size.height);
        
        [view addSubview:legendView];
        
        legendView.hidden = YES;
        
        // attach hide & show handle gestures
        //
        UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.dragHandle addGestureRecognizer:leftSwipe];
        leftSwipe.enabled = YES;
        
        UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.dragHandle addGestureRecognizer:rightSwipe];
        rightSwipe.enabled = NO;
        
        UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        tap.numberOfTapsRequired = 1;
        [self.dragHandle addGestureRecognizer:tap];
        tap.enabled = YES;
        
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
    [backgroundView release];
    [label release];
    [scroller release];
    [pager release];
    [dragHandle release];
    
    [super dealloc];
}

#pragma mark -

- (void)setLegendSources:(NSArray *)legendSources
{
    if ( ! [legendSources isEqualToArray:_legendSources])
    {
        // swap out new sources
        //
        [_legendSources release];
        _legendSources = [legendSources retain];
        
        // get TileMill CSS once for repeated use
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
                [legends addObject:[NSString stringWithFormat:@"<body style='background-color: transparent;'> \
                                                                <div id='wax-legend' \
                                                                  class='wax-legend' \
                                                                  style='background-color: white;'> \
                                                                    %@ \
                                                                </div> \
                                                                <style type='text/css'> \
                                                                    %@ \
                                                                    %@ \
                                                                </style> \
                                                                </body>", [source performSelector:@selector(legend)], controls, reset]];

        if ([legends count])
        {
            // reverse order (rightmost = topmost)
            //
            [legends setArray:[[legends reverseObjectEnumerator] allObjects]];
            
            // show UI if needed
            //
            self.legendView.hidden = NO;
            
            [self.legendView.superview bringSubviewToFront:self.legendView];
            
            if (self.legendView.alpha < 1.0)
            {
                [UIView animateWithDuration:0.1
                                      delay:0.0
                                    options:UIViewAnimationCurveEaseOut
                                 animations:^(void)
                                 {
                                     self.legendView.alpha = 1.0;
                                 }
                                 completion:nil];
            }
            
            // iterate legends, making web views
            //
            NSMutableArray *newLegendViews = [NSMutableArray array];
            
            for (NSString *legend in legends)
            {
                UIWebView *webView = [[[UIWebView alloc] initWithFrame:self.scroller.frame] autorelease];
                
                [webView loadHTMLString:legend baseURL:nil];
                
                webView.frame = CGRectMake([newLegendViews count] * self.scroller.frame.size.width + 10, 
                                           0, 
                                           webView.frame.size.width - 20, 
                                           webView.frame.size.height);
                
                webView.delegate = self;
                
                webView.scrollView.alwaysBounceVertical   = YES;
                webView.scrollView.alwaysBounceHorizontal = NO;
                
                webView.scrollView.directionalLockEnabled = YES;
                
                webView.backgroundColor = [UIColor clearColor];
                webView.opaque = NO;
                
                webView.layer.shadowColor   = [[UIColor grayColor] CGColor];
                webView.layer.shadowOffset  = CGSizeMake(-1.0, 1.0);
                webView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:webView.bounds] CGPath];
                webView.layer.shadowRadius  = 5.0;
                webView.layer.shadowOpacity = 0.0;
                
                // add gesture for tap-to-toggle mode
                //
                UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
                
                tap.numberOfTapsRequired = 1;
                tap.delegate = self;
                
                [webView addGestureRecognizer:tap];
                
                // remove scroller shadow
                //
                for (UIView *shadowView in webView.scrollView.subviews)
                    if ([shadowView isKindOfClass:[UIImageView class]])
                        [shadowView setHidden:YES];

                [newLegendViews addObject:webView];
                
                // hide until loaded
                //
                webView.alpha = 0.0;                
            }
            
            // replace in view hierarchy
            //
            [self.scroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

            for (UIWebView *webView in newLegendViews)
                [self.scroller addSubview:webView];

            // update scroller & pager
            //
            self.scroller.contentSize = CGSizeMake([self.scroller.subviews count] * self.scroller.frame.size.width, 
                                                   self.scroller.frame.size.height);
            
            [self.scroller scrollRectToVisible:CGRectMake(0, 0, 0, 0) animated:NO];
            
            self.pager.numberOfPages = [self.scroller.subviews count];
            
            self.pager.currentPage = 0;
            
            [self scrollViewDidScroll:self.scroller];
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
        // handle swipe: expand/collapse interface
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
        
        // disable gesture that got us here
        //
        [swipe.view.gestureRecognizers makeObjectsPerformSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES]];
        
        swipe.enabled = NO;
    }
    else if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        if ([gesture.view isEqual:self.dragHandle])
        {
            // handle tap: expand/collapse interface
            //
            if (self.dragHandle.image)
                [self collapseInterfaceAnimated:YES];
            
            else
                [self expandInterfaceAnimated:YES];
        }
        else
        {
            // legend tap: temporarily show interface
            //
            [self showInterface];
            [self performSelector:@selector(hideInterface) withObject:nil afterDelay:kDSMapBoxLegendManagerPostInteractionDelay];
        }
    }
}

- (void)showInterface
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // bring up management UI & move legends up
    //
    [UIView animateWithDuration:kDSMapBoxLegendManagerHideShowDuration
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void)
                     {
                         self.backgroundView.alpha = 1.0;
                         self.label.alpha          = 1.0;
                         self.pager.alpha          = 1.0;
                         self.dragHandle.alpha     = 1.0;
                         
                         self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                                            self.legendView.superview.frame.size.height - self.initialHeight, 
                                                            self.legendView.frame.size.width, 
                                                            self.initialHeight);
                         
                         for (UIView *subview in self.scroller.subviews)
                             subview.center = CGPointMake(subview.center.x, roundf(self.scroller.frame.size.height / 2));
                     }
                     completion:nil];

    
    // adjust layer shadows
    //
    for (UIView *webView in self.scroller.subviews)
        [webView.layer animateShadowOpacityTo:0.0 withDuration:kDSMapBoxLegendManagerHideShowDuration];

    [backgroundView.layer animateShadowOpacityTo:1.0 withDuration:kDSMapBoxLegendManagerHideShowDuration];
    
    // make sure we can page again
    //
    self.scroller.scrollEnabled = YES;
}

- (void)hideInterface
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // determine which legend we are on
    //
    UIView *activeWebView = [self.scroller.subviews objectAtIndex:self.scroller.contentOffset.x / self.scroller.frame.size.width];
    
    // transition to minimal UI mode & move legends down 
    //
    [UIView animateWithDuration:kDSMapBoxLegendManagerHideShowDuration
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void)
                     {
                         self.backgroundView.alpha = 0.0;
                         self.label.alpha          = 0.0;
                         self.pager.alpha          = 0.0;
                         
                         if (self.dragHandle.image)
                             self.dragHandle.alpha = 0.0;
                         
                         CGFloat newOverallHeight = activeWebView.frame.size.height + (self.legendView.frame.size.height - self.scroller.frame.size.height) + 10;
                         
                         self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                                            self.legendView.superview.frame.size.height - newOverallHeight, 
                                                            self.legendView.frame.size.width, 
                                                            newOverallHeight);
                         
                         activeWebView.center = CGPointMake(activeWebView.center.x, roundf(self.scroller.frame.size.height / 2));
                     }
                     completion:^(BOOL finished)
                     {
                         if (finished)
                         {
                             // disable paging between legends
                             //
                             self.scroller.scrollEnabled = NO;
                         }
                     }];
    
    // re-add shadow to active legend
    //
    [activeWebView.layer animateShadowOpacityTo:0.5 withDuration:kDSMapBoxLegendManagerHideShowDuration];

    // remove background shadow
    //
    [backgroundView.layer animateShadowOpacityTo:0.0 withDuration:kDSMapBoxLegendManagerHideShowDuration];
    
    // flash scrollers when possible as size hint
    //
    [((UIWebView *)activeWebView).scrollView flashScrollIndicators];
}

- (void)collapseInterfaceAnimated:(BOOL)animated
{
    self.dragHandle.image = nil;
    
    void (^centerBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x - self.backgroundView.frame.size.width, 
                                             self.legendView.center.y);
    };
    
    void (^opacityBlock)(void) = ^
    {
        self.backgroundView.layer.shadowOpacity = 0.0;
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerCollapseExpandDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             centerBlock();
                         }
                         completion:^(BOOL finished)
                         {
                             opacityBlock();
                         }];
    }        
    else
    {
        centerBlock();
        opacityBlock();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // make sure it goes away shown
    //
    [self showInterface];
}

- (void)expandInterfaceAnimated:(BOOL)animated
{
    self.dragHandle.image = [UIImage imageNamed:@"grabber.png"];
    
    void (^centerBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x + self.backgroundView.frame.size.width, 
                                             self.legendView.center.y);
    };
    
    void (^opacityBlock)(void) = ^
    {
        self.backgroundView.layer.shadowOpacity = 1.0;
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kDSMapBoxLegendManagerCollapseExpandDuration
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             centerBlock();
                             opacityBlock();
                         }
                         completion:nil];
    }
    else
    {
        centerBlock();
        opacityBlock();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // show full interface, then hide it
    //
    [self showInterface];
    [self performSelector:@selector(hideInterface) withObject:nil afterDelay:kDSMapBoxLegendManagerPostInteractionDelay];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // update pager
    //
    self.pager.currentPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    // get active legends
    //
    NSMutableArray *activeLegendSources = [NSMutableArray array];
    
    for (id <RMTileSource>source in self.legendSources)
        if ([source respondsToSelector:@selector(legend)] && [[source performSelector:@selector(legend)] length])
            [activeLegendSources addObject:source];
    
    // reverse as in legend stacking order
    //
    [activeLegendSources setArray:[[activeLegendSources reverseObjectEnumerator] allObjects]];

    // update label
    //
    self.label.text = ([activeLegendSources count] ? [((id <RMTileSource>)[activeLegendSources objectAtIndex:self.pager.currentPage]) shortName] : nil);
    
    // show interface
    //
    [self showInterface];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // cancel show/hide requests & hide after a delay
    //
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(hideInterface) withObject:nil afterDelay:kDSMapBoxLegendManagerPostInteractionDelay];
}

#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // allow tap gestures in UIWebView
    //
    return YES;
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
    // auto-size to content
    //
    CGFloat renderHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight;"] floatValue] + 2;
    
    if (renderHeight < webView.frame.size.height)
    {
        webView.frame  = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, renderHeight);
        webView.center = CGPointMake(webView.center.x, roundf(webView.superview.frame.size.height / 2));

        webView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:webView.bounds] CGPath];
    }
    
    // theme link color
    //
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"links = document.getElementsByTagName('a'); \
                                                                                 for (i = 0; i < links.length; i++)          \
                                                                                     links[i].style.color = '#%@';", [kMapBoxBlue hexStringFromColor]]];
        
    // fade in this loaded legend
    //
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         webView.alpha = 1.0;
                     }
                     completion:nil];
    
    // hide interface after a delay
    //
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(hideInterface) withObject:nil afterDelay:kDSMapBoxLegendManagerPostInteractionDelay];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [[UIApplication sharedApplication] openURL:((DSMapBoxAlertView *)alertView).context];
}

@end