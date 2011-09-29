//
//  DSMapBoxBalloonController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxBalloonController.h"

@implementation DSMapBoxBalloonController

@synthesize name;
@synthesize description;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];

    if (self != nil)
    {
        name        = [[NSString stringWithString:@""] retain];
        description = [[NSString stringWithString:@""] retain];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *balloonText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"balloon" ofType:@"html"]
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
    
    if (self.name && [self.name length])
    {
        balloonText = [balloonText stringByReplacingOccurrencesOfString:@"##name##" withString:self.name];
    }
    else
    {
        balloonText = [balloonText stringByReplacingOccurrencesOfString:@"<strong>##name##</strong>" withString:@""];
        balloonText = [balloonText stringByReplacingOccurrencesOfString:@"<br/>"                     withString:@""];
    }
    
    balloonText = [balloonText stringByReplacingOccurrencesOfString:@"##description##" withString:self.description];
    
    webView.dataDetectorTypes = UIDataDetectorTypeLink;

    [webView loadHTMLString:balloonText baseURL:nil];
}

- (void)dealloc
{
    [webView stopLoading];

    webView.delegate = nil;
    
    [name release];
    [description release];
    
    [super dealloc];
}

#pragma mark -

- (void)setName:(NSString *)inName
{
    [name release];
    
    if ( ! inName)
        name = [[NSString stringWithString:@"Untitled"] retain];
    
    else
        name = [inName retain];
}

- (void)setDescription:(NSString *)inDescription
{
    [description release];
    
    if ( ! inDescription)
        description = [[NSString stringWithString:@"(no description)"] retain];
    
    else
        description = [inDescription retain];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // first load is about:blank before content is injected
    //
    if ( ! [[[request URL] scheme] isEqualToString:@"about"])
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        
        return NO;
    }
    
    return YES;
}

@end