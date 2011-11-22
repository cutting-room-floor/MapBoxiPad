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

@interface DSMapBoxLegendManager ()

@property (nonatomic, retain) IBOutlet UIView *legendView;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIScrollView *scroller;
@property (nonatomic, retain) IBOutlet StyledPageControl *pager;
@property (nonatomic, retain) IBOutlet UIImageView *dragHandle;

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

- (id)initWithView:(UIView *)view
{
    self = [super init];
    
    if (self)
    {
        _legendSources = [[NSArray array] retain];

        // load UI & pretty it up
        //
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];

        dragHandle.layer.borderColor  = [[UIColor colorWithWhite:0.5 alpha:0.25] CGColor];
        dragHandle.layer.borderWidth  = 1.0;
        dragHandle.layer.cornerRadius = 15.0;

        label.layer.borderColor = [[UIColor blackColor] CGColor];
        label.layer.borderWidth = 1.0;
        
        // make an L-shaped shadow on the edges of the main background
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
        
        // get TileMill CSS for repeated use
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
                                                                <div    id='wax-legend' \
                                                                     class='wax-legend' \
                                                                     style='background-color: white; font-family: Arial, sans-serif;'> \
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
                
                webView.frame = CGRectMake([newLegendViews count] * self.scroller.frame.size.width, 
                                           0, 
                                           webView.frame.size.width, 
                                           webView.frame.size.height);
                
                webView.delegate = self;
                
                webView.scrollView.alwaysBounceVertical   = YES;
                webView.scrollView.alwaysBounceHorizontal = NO;
                
                webView.scrollView.directionalLockEnabled = YES;
                
                webView.backgroundColor = [UIColor clearColor];
                webView.opaque = NO;
                
                // add gesture for tap-to-toggle-label
                //
                UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
                
                tap.numberOfTapsRequired = 1;
                tap.delegate = self;
                
                [webView addGestureRecognizer:tap];
                
                if ( ! self.legendView.gestureRecognizers)
                    [self.legendView addGestureRecognizer:tap];
                
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
        UISwipeGestureRecognizer *swipe = (UISwipeGestureRecognizer *)gesture;
        
        if (swipe.direction == UISwipeGestureRecognizerDirectionLeft)
        {
            // left swipe in top or bottom to hide
            //        
            self.dragHandle.image = nil;

            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.center = CGPointMake(self.legendView.center.x - self.backgroundView.frame.size.width, 
                                                                      self.legendView.center.y);
                             }
                             completion:^(BOOL finished)
                             {
                                 self.backgroundView.layer.shadowOpacity = 0.0;
                             }];
        }
        else if (swipe.direction == UISwipeGestureRecognizerDirectionRight)
        {
            // right swipe anywhere to show
            //
            self.backgroundView.layer.shadowOpacity = 1.0;
            
            self.dragHandle.image = [UIImage imageNamed:@"grabber.png"];

            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.center = CGPointMake(self.legendView.center.x + self.backgroundView.frame.size.width, 
                                                                      self.legendView.center.y);
                             }
                             completion:nil];
        }
        
        [swipe.view.gestureRecognizers makeObjectsPerformSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES]];
        
        swipe.enabled = NO;
    }
    else if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        // effectively show, then hide scroller
        //
        [self scrollViewDidScroll:self.scroller];

        dispatch_delayed_ui_action(1.0, ^(void) { [self scrollViewDidEndDecelerating:self.scroller]; });
    }
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

    // show label & pager and hide drag handle
    //
    self.label.alpha           = 1.0;
    self.pager.alpha           = 1.0;
    self.dragHandle.alpha      = 0.0;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // fade out label UI
    //
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         self.label.alpha           = 0.0;
                         self.pager.alpha           = 0.0;
                         self.dragHandle.alpha      = 1.0;
                     }
                     completion:nil];
    
    // flash scrollers when possible as size hint
    //
    [((UIWebView *)[scrollView.subviews objectAtIndex:scrollView.contentOffset.x / scrollView.frame.size.width]).scrollView flashScrollIndicators];
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
    // size down if needed
    //
    CGFloat renderHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('wax-legend')[0].clientHeight;"] floatValue] + 2;
    
    if (renderHeight < webView.frame.size.height)
    {
        webView.frame  = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, renderHeight);
        webView.center = CGPointMake(roundf(webView.center.x), roundf(webView.superview.frame.size.height / 2));
        webView.scrollView.scrollEnabled = NO;
    }
    
    // theme links
    //
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"links = document.getElementsByTagName('a'); \
                                                                                 for (i = 0; i < links.length; i++)          \
                                                                                     links[i].style.color = '#%@';", [kMapBoxBlue hexStringFromColor]]];
        
    // fade in view
    //
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void)
                     {
                         webView.alpha = 1.0;
                     }
                     completion:nil];
    
    // fade out label UI
    //
    dispatch_delayed_ui_action(1.0, ^(void) { [self scrollViewDidEndDecelerating:self.scroller]; });
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [[UIApplication sharedApplication] openURL:((DSMapBoxAlertView *)alertView).context];
}

@end