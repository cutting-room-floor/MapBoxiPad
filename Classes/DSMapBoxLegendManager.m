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
        
        [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxLegendView" owner:self options:nil];
        
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
        
        UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
        tap.numberOfTapsRequired = 1;
        [self.legendView addGestureRecognizer:tap];
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
                
            if (legend && [legend length])
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
                
                self.scroller.contentSize = CGSizeMake(([self.scroller.subviews count] + 1) * self.scroller.frame.size.width, 
                                                       self.scroller.frame.size.height);
                
                [self.scroller addSubview:webView];
                
                self.pager.numberOfPages++;
            }
        }
        
        [self.scroller scrollRectToVisible:CGRectMake(self.scroller.contentSize.width - 10 - self.scroller.frame.size.width, 0, 10, 10) animated:NO];
        
        self.pager.currentPage = self.pager.numberOfPages - 1;

        dispatch_delayed_ui_action(0.5, ^(void)
        {
            [self.scroller scrollRectToVisible:CGRectMake(self.scroller.contentSize.width - 10, 0, 10, 10) animated:YES];
        });
    }
}

#pragma mark -

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    // respond to gestures in bottom to hide & show
    //
    if ([gestureRecognizer locationInView:self.legendView].y > self.legendView.frame.size.height - self.dragHandle.frame.size.height)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        
        if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] && ((UISwipeGestureRecognizer *)gestureRecognizer).direction == UISwipeGestureRecognizerDirectionLeft)
        {
            // left swipe to hide
            //
            self.legendView.center = CGPointMake(self.legendView.frame.size.width / -2 + self.dragHandle.frame.size.width, self.legendView.center.y);
        }
        else if (([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] && ((UISwipeGestureRecognizer *)gestureRecognizer).direction == UISwipeGestureRecognizerDirectionRight) || [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
        {
            // right swipe or tap to show
            //
            self.legendView.center = CGPointMake(self.legendView.frame.size.width / 2, self.legendView.center.y);
        }
        
        [UIView commitAnimations];
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
    self.label.text = [((id <RMTileSource>)[self.legendSources objectAtIndex:self.pager.currentPage]) shortName];
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