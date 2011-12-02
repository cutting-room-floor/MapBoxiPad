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
@property (nonatomic, assign) BOOL collapsed;

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
@synthesize contentWebView;
@synthesize dragHandle;
@synthesize collapsed;

- (id)initWithView:(UIView *)view
{
    self = [super init];
    
    if (self)
    {
        _legendSources = [[NSArray array] retain];

        // load UI & pretty it up
        //
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        
        maskLayer.frame = dragHandle.bounds;
        maskLayer.path  = [[UIBezierPath bezierPathWithRoundedRect:dragHandle.bounds
                                                 byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight
                                                       cornerRadii:CGSizeMake(15.0, 15.0)] CGPath];
        
        dragHandle.layer.mask = maskLayer;

        // start with legend in lower-left, hidden by default
        //
        legendView.frame = CGRectMake(view.frame.origin.x + 5, 
                                      44 + 5, //view.frame.size.height - 500, //legendView.frame.size.height, 
                                      500, //legendView.frame.size.width, 
                                      view.frame.size.height - 5); //500); //legendView.frame.size.height);
        
        [view addSubview:legendView];
        
        legendView.hidden = YES;
        
        // attach hide & show handle gestures
        //
        UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
//        [self.dragHandle addGestureRecognizer:leftSwipe];
//        leftSwipe.enabled = YES;
        
        UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.dragHandle addGestureRecognizer:rightSwipe];
//        rightSwipe.enabled = NO;
        
        UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        tap.numberOfTapsRequired = 1;
        [self.dragHandle addGestureRecognizer:tap];
        tap.enabled = YES;
        
        
        
        [contentWebView addGestureRecognizer:leftSwipe];
//        [contentWebView addGestureRecognizer:rightSwipe];
        
        
        
        // start collapsed if left that way
        //
//        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"legendCollapsed"])
//            [self collapseInterfaceAnimated:NO];
    }
    
    return self;
}

- (void)dealloc
{
    [_legendSources release];
    [legendView release];
    [contentWebView release];
    [dragHandle release];
    
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
            NSString *legendContent = [NSString stringWithFormat:@"<body style='background-color: transparent;'> \
                                                                   <div id='wax-legend' \
                                                                     class='wax-legend' \
                                                                     style='background-color: white;'> \
                                                                       %@ \
                                                                   </div> \
                                                                   <style type='text/css'> \
                                                                       %@ \
                                                                       %@ \
                                                                       .wax-legend { \
                                                                         max-height: 1200px; \
                                                                       } \
                                                                   </style> \
                                                                   </body>", [legends componentsJoinedByString:@""], controls, reset];
            
            // show UI if needed
            //
            self.legendView.hidden = NO;
            
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
            
            
//            [self.legendView.superview bringSubviewToFront:self.legendView];
            
            
            
            
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
            
            
            
            
            // iterate legends, making web views
            //
//            NSMutableArray *newLegendViews = [NSMutableArray array];
//            
//            for (NSString *legend in legends)
//            {
//                UIWebView *webView = [[[UIWebView alloc] initWithFrame:self.scroller.frame] autorelease];
                
//            self.legendView.frame = CGRectMake(0, contentWebView.superview.frame.size.height - 1, 1, 1);
            
            
                [contentWebView loadHTMLString:legendContent baseURL:nil];
                
//                webView.frame = CGRectMake([newLegendViews count] * self.scroller.frame.size.width + 10, 
//                                           0, 
//                                           webView.frame.size.width - 20, 
//                                           webView.frame.size.height);
                
//                webView.delegate = self;
                
            contentWebView.scrollView.bounces = YES;
            contentWebView.scrollView.alwaysBounceVertical   = YES;
            contentWebView.scrollView.alwaysBounceHorizontal = NO;

//                webView.scrollView.directionalLockEnabled = YES;
                
                contentWebView.scrollView.delegate = self;
                
            contentWebView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];
                contentWebView.opaque = NO;
                
//                contentWebView.layer.shadowColor   = [[UIColor grayColor] CGColor];
//                contentWebView.layer.shadowOffset  = CGSizeMake(-1.0, 1.0);
//                contentWebView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:webView.bounds] CGPath];
//                contentWebView.layer.shadowRadius  = 5.0;
//                contentWebView.layer.shadowOpacity = 0.0;
                
                // add gesture for tap-to-toggle mode
                //
                UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
                
                tap.numberOfTapsRequired = 1;
                tap.delegate = self;
                
                [contentWebView addGestureRecognizer:tap];
                
                // remove scroller shadow
                //
                for (UIView *shadowView in contentWebView.scrollView.subviews)
                    if ([shadowView isKindOfClass:[UIImageView class]])
                        [shadowView setHidden:YES];

//                [newLegendViews addObject:webView];
                
                // hide until loaded
                //
                contentWebView.alpha = 0.0;                
//            }
            
            // replace in view hierarchy
            //
//            [self.scroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//
//            for (UIWebView *webView in newLegendViews)
//                [self.scroller addSubview:webView];

            // update scroller & pager
            //
//            self.scroller.contentSize = CGSizeMake([self.scroller.subviews count] * self.scroller.frame.size.width, 
//                                                   self.scroller.frame.size.height);
//            
//            [self.scroller scrollRectToVisible:CGRectMake(0, 0, 0, 0) animated:NO];
//            
//            [self scrollViewDidScroll:self.scroller];
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
//        [swipe.view.gestureRecognizers makeObjectsPerformSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES]];
//        
//        swipe.enabled = NO;
    }
    else if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        if ([gesture.view isEqual:self.dragHandle])
        {
            // handle tap: expand/collapse interface
            //
            if ( ! self.collapsed)
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
//                         self.contentWebView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];

                         self.dragHandle.alpha = 1.0;
                         
//                         self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
//                                                            self.legendView.frame.origin.y - (self.initialHeight - self.legendView.frame.size.height),
//                                                            self.legendView.frame.size.width, 
//                                                            self.initialHeight);
//                         
//                         for (UIView *subview in self.scroller.subviews)
//                             subview.center = CGPointMake(subview.center.x, roundf(self.scroller.frame.size.height / 2));
                     }
                     completion:NULL];

    
    // adjust layer shadows
    //
//    for (UIView *webView in self.scroller.subviews)
//        [webView.layer animateShadowOpacityTo:0.0 withDuration:kDSMapBoxLegendManagerHideShowDuration];

    // make sure we can page again
    //
//    self.scroller.scrollEnabled = YES;
}

- (void)hideInterface
{
    if (self.collapsed)
        return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // determine which legend we are on
    //
//    UIView *activeWebView = [self.scroller.subviews objectAtIndex:self.scroller.contentOffset.x / self.scroller.frame.size.width];
    
    // transition to minimal UI mode & move legends down 
    //
    [UIView animateWithDuration:kDSMapBoxLegendManagerHideShowDuration
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void)
                     {
//                         self.contentWebView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];

                         self.dragHandle.alpha = 0.0;
                         
//                         CGFloat newOverallHeight = activeWebView.frame.size.height + (self.legendView.frame.size.height - self.scroller.frame.size.height) + 10;
//                         
//                         self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
//                                                            self.legendView.frame.origin.y + (self.legendView.frame.size.height - newOverallHeight),
//                                                            self.legendView.frame.size.width, 
//                                                            newOverallHeight);
//                         
//                         activeWebView.center = CGPointMake(activeWebView.center.x, roundf(self.scroller.frame.size.height / 2));
                     }
                     completion:^(BOOL finished)
                     {
                         if (finished)
                         {
                             // disable paging between legends
                             //
//                             self.scroller.scrollEnabled = NO;
                         }
                     }];
    
    // re-add shadow to active legend
    //
//    [activeWebView.layer animateShadowOpacityTo:0.5 withDuration:kDSMapBoxLegendManagerHideShowDuration];

    // flash scrollers when possible as size hint
    //
//    [((UIWebView *)activeWebView).scrollView flashScrollIndicators];
}

- (void)collapseInterfaceAnimated:(BOOL)animated
{
    self.collapsed = YES;

    self.dragHandle.hidden = NO;
    
    
    void (^centerBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x - self.contentWebView.frame.size.width - 5, 
                                             self.legendView.center.y);
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
                         completion:NULL];
    }        
    else
    {
        centerBlock();
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"legendCollapsed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // make sure it goes away shown
    //
    [self showInterface];
}

- (void)expandInterfaceAnimated:(BOOL)animated
{
    self.collapsed = NO;
    
    self.dragHandle.hidden = YES;
    
    
    void (^centerBlock)(void) = ^
    {
        self.legendView.center = CGPointMake(self.legendView.center.x + self.contentWebView.frame.size.width + 5, 
                                             self.legendView.center.y);
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
                         completion:NULL];
    }
    else
    {
        centerBlock();
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
    if ([scrollView isEqual:contentWebView.scrollView])
    {
//        NSLog(@"here");
        
        return;
    }
        
    
    if (NO) //[scrollView isEqual:self.scroller])
    {
//        // paging scroller - handle paging
//        //
//        self.pager.currentPage = scrollView.contentOffset.x / scrollView.frame.size.width;
//        
//        // get active legends
//        //
//        NSMutableArray *activeLegendSources = [NSMutableArray array];
//        
//        for (id <RMTileSource>source in self.legendSources)
//            if ([source respondsToSelector:@selector(legend)] && [[source performSelector:@selector(legend)] length])
//                [activeLegendSources addObject:source];
//        
//        // reverse as in legend stacking order
//        //
//        [activeLegendSources setArray:[[activeLegendSources reverseObjectEnumerator] allObjects]];
//
//        // update label
//        //
//        self.label.text = ([activeLegendSources count] ? [((id <RMTileSource>)[activeLegendSources objectAtIndex:self.pager.currentPage]) shortName] : nil);
        
        // show interface
        //
        [self showInterface];
    }
    else
    {
        // individual webview scroller - if in hidden mode, hide visible webview shadow
        //
//        if (self.backgroundView.alpha < 1.0)
//            [scrollView.superview.layer animateShadowOpacityTo:0.0 withDuration:0.25];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.contentWebView.scrollView])
    {
        // paging scroller - cancel show/hide requests & hide after a delay
        //
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideInterface) withObject:nil afterDelay:kDSMapBoxLegendManagerPostInteractionDelay];
    }
    else
    {
        // individual webview scroller - bring webview shadow back
        //
//        if (self.backgroundView.alpha < 1.0)
//            [scrollView.superview.layer animateShadowOpacityTo:0.5 withDuration:0.25];
    }
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
    
//    NSLog(@"webview frame: %f x %f", webView.frame.size.width, webView.frame.size.height);
//    NSLog(@"scroller frame: %f x %f", webView.scrollView.frame.size.width, webView.scrollView.frame.size.height);
//    NSLog(@"body clientWidth/Height: %@ %@", [webView stringByEvaluatingJavaScriptFromString:@"document.body.clientWidth"], [webView stringByEvaluatingJavaScriptFromString:@"document.body.clientHeight"]);
//    NSLog(@"body offsetWidth/Height: %@ %@", [webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetWidth"], [webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"]);
//    NSLog(@"div.wax-legend clientWidth/Height: %@ %@", [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientWidth"], [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight"]);
//    
    
    
    
    // auto-size to content
    //
    
//    CGSize size =[webView sizeThatFits:CGSizeZero];
//    
//    CGRect frame = webView.frame;
//    frame.origin.y = frame.origin.y - (size.height - frame.size.height);
//    frame.size.height = size.height;
//    webView.frame = frame;

    
    
//    CGRect frame = webView.frame;
//    frame.size.height = 1;
//    webView.frame = frame;
//    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
//    frame.size = fittingSize;
//    webView.frame = frame;
//    
//    NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
//
//    
//    
//    
//    CGFloat renderHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.clientHeight"] floatValue]; //getElementsByClassName('wax-legend')[0].clientHeight;"] floatValue] + 2;
//    
//    
//    //NSLog(@"scroll height is %f", webView.scrollView.contentSize.height);
//    
//    
//    //NSLog(@"new height is %f", renderHeight);
//    
//    
//    if (YES) //renderHeight < webView.frame.size.height)
//    {
    
    CGFloat renderHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight"] floatValue];
    CGFloat renderWidth  = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientWidth"]  floatValue];    
        
    self.legendView.frame = CGRectMake(self.legendView.frame.origin.x, 
                                           self.legendView.superview.frame.size.height - renderHeight, // self.legendView.frame.origin.y - (renderHeight - self.legendView.frame.size.height), // - 44, 
                                           renderWidth + 45, //self.legendView.frame.size.width, 
                                           renderHeight);
//        
    
    
//    self.contentWebView.scrollView.scrollEnabled = NO;
    
    
//    self.contentWebView.scrollView.layer.borderColor = [[UIColor purpleColor] CGColor];
//    self.contentWebView.scrollView.layer.borderWidth = 5.0;
    
    
//    NSLog(@"%f %f", self.contentWebView.scrollView.contentSize.width, self.contentWebView.scrollView.contentSize.height);
    
    
    self.contentWebView.scrollView.contentSize = self.contentWebView.scrollView.bounds.size;
    
    
    
    
//        NSLog(@"new overall height is %f", self.legendView.frame.size.height);
//        
////        webView.frame  = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, renderHeight);
////        webView.center = CGPointMake(webView.center.x, roundf(self.scroller.frame.size.height / 2));
//
//        webView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:webView.bounds] CGPath];
//    }
    
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
                     completion:NULL];
    
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