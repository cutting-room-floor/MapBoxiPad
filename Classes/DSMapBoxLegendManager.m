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

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLegendManager ()

@property (nonatomic, retain) IBOutlet UIView *legendView;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIScrollView *scroller;
@property (nonatomic, retain) IBOutlet UIPageControl *pager;
@property (nonatomic, retain) IBOutlet UIImageView *dragHandle;

@end

#pragma mark -

@implementation DSMapBoxLegendManager

@synthesize legendSources=_legendSources;
@synthesize legendView;
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

        legendView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:legendView.frame] CGPath];
        legendView.layer.shadowColor   = [[UIColor grayColor] CGColor];
        legendView.layer.shadowOffset  = CGSizeMake(0, 0);
        legendView.layer.shadowOpacity = 0.25;
        legendView.layer.shadowRadius  = 10.0;
        
        legendView.layer.borderColor   = [[UIColor grayColor] CGColor];
        legendView.layer.borderWidth   = 1.0;
        
        // start with legend in lower-left
        //
        legendView.frame = CGRectMake(view.frame.origin.x, 
                                      view.frame.size.height - legendView.frame.size.height, 
                                      legendView.frame.size.width, 
                                      legendView.frame.size.height);
        
        [view addSubview:legendView];
        
        // attach hide & show gestures
        //
        UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.legendView addGestureRecognizer:leftSwipe];
        
        UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.legendView addGestureRecognizer:rightSwipe];
    }
    
    return self;
}

- (void)dealloc
{
    [_legendSources release];
    [legendView release];
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
        [_legendSources release];
        _legendSources = [legendSources retain];
        
        [self.scroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        self.pager.numberOfPages = 0;
        
        NSString *controls = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"controls" ofType:@"css"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];

        for (id <RMTileSource>source in _legendSources)
        {
            NSString *legend = nil;
            
            if ([source respondsToSelector:@selector(legend)])
                legend = [source performSelector:@selector(legend)];
                
            if ([legend length])
            {                
                legend = [NSString stringWithFormat:@"<div id='wax-legend' class='wax-legend'> \
                                                          %@                                   \
                                                      </div>                                   \
                                                      <div style='clear: both;'>               \
                                                      </div>                                   \
                                                      <style type='text/css'>                  \
                                                          %@                                   \
                                                      </style>", legend, controls];
                
                UIWebView *webView = [[[UIWebView alloc] initWithFrame:self.scroller.frame] autorelease];
                
                [webView loadHTMLString:legend baseURL:nil];
                
                webView.frame = CGRectMake([self.scroller.subviews count] * self.scroller.frame.size.width, 
                                           0, 
                                           webView.frame.size.width, 
                                           webView.frame.size.height);
                
                webView.delegate = self;
                
                webView.scrollView.bounces = NO;
                
                webView.layer.borderColor = [[UIColor grayColor] CGColor];
                webView.layer.borderWidth = 1.0;
                
                self.scroller.contentSize = CGSizeMake(([self.scroller.subviews count] + 1) * self.scroller.frame.size.width, 
                                                       self.scroller.frame.size.height);
                
                [self.scroller addSubview:webView];
                
                self.pager.numberOfPages++;
            }
        }
        
        if (self.pager.numberOfPages)
        {
            [UIView animateWithDuration:0.1
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.alpha = 1.0;
                             }
                             completion:^(BOOL finished)
                             {
                             }];
            
            [self.scroller scrollRectToVisible:CGRectMake(self.scroller.contentSize.width - 10 - self.scroller.frame.size.width, 0, 10, 10) animated:NO];
            
            [self scrollViewDidScroll:self.scroller];
            
            dispatch_delayed_ui_action(0.5, ^(void)
            {
                [self.scroller scrollRectToVisible:CGRectMake(self.scroller.contentSize.width - 10, 0, 10, 10) animated:YES];
            });
        }
        else
        {
            [UIView animateWithDuration:0.1
                                  delay:0.0
                                options:UIViewAnimationCurveEaseOut
                             animations:^(void)
                             {
                                 self.legendView.alpha = 0.0;
                             }
                             completion:^(BOOL finished)
                             {
                             }];
        }
    }
}

#pragma mark -

- (void)handleGesture:(UISwipeGestureRecognizer *)swipe
{
    if (([swipe locationInView:self.legendView].y <= self.dragHandle.frame.size.height || [swipe locationInView:self.legendView].y >= self.legendView.frame.size.height - self.dragHandle.frame.size.height) && swipe.direction == UISwipeGestureRecognizerDirectionLeft && self.legendView.alpha == 1.0)
    {
        // left swipe in top or bottom to hide
        //
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             self.legendView.center = CGPointMake(self.legendView.frame.size.width / -2 + 4, 
                                                                  self.legendView.center.y);
                         }
                         completion:^(BOOL finished)
                         {
                             self.legendView.alpha = 0.75;
                            
                             self.label.alpha    = 0.0;
                             self.scroller.alpha = 0.0;
                             self.pager.alpha    = 0.0;
                             
                             self.dragHandle.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:self.dragHandle.frame] CGPath];
                             self.dragHandle.layer.shadowOpacity = self.legendView.layer.shadowOpacity;
                             self.dragHandle.layer.shadowOffset  = self.legendView.layer.shadowOffset;
                             self.dragHandle.layer.shadowColor   = self.legendView.layer.shadowColor;
                             self.dragHandle.layer.shadowRadius  = self.legendView.layer.shadowRadius;
                             
                             self.legendView.layer.shadowOpacity = 0.0;
                         }];
    }
    else if (swipe.direction == UISwipeGestureRecognizerDirectionRight && self.legendView.alpha < 1.0)
    {
        // right swipe anywhere to show
        //
        self.legendView.alpha = 1.0;
        
        self.label.alpha    = 1.0;
        self.scroller.alpha = 1.0;
        self.pager.alpha    = 1.0;
        
        self.legendView.layer.shadowOpacity = 0.5;
        self.dragHandle.layer.shadowOpacity = 0.0;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void)
                         {
                             self.legendView.center = CGPointMake(self.legendView.frame.size.width / 2, 
                                                                  self.legendView.center.y);

                         }
                         completion:^(BOOL finished)
                         {
                         }];
    }
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // update pager
    //
    self.pager.currentPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    // update label
    //
    NSMutableArray *activeLegendSources = [NSMutableArray array];
    
    for (id <RMTileSource>source in self.legendSources)
        if ([source respondsToSelector:@selector(legend)] && [[source performSelector:@selector(legend)] length])
            [activeLegendSources addObject:source];
    
    self.label.text = ([activeLegendSources count] ? [((id <RMTileSource>)[activeLegendSources objectAtIndex:self.pager.currentPage]) shortName] : nil);
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

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [[UIApplication sharedApplication] openURL:((DSMapBoxAlertView *)alertView).context];
}
         
@end