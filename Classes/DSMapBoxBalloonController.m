//
//  DSMapBoxBalloonController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxBalloonController.h"

@implementation DSMapBoxBalloonController

@synthesize name;
@synthesize description;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *balloon = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"balloon" ofType:@"html"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    balloon = [balloon stringByReplacingOccurrencesOfString:@"##name##"        withString:self.name];
    balloon = [balloon stringByReplacingOccurrencesOfString:@"##description##" withString:self.description];
    
    [webView loadHTMLString:balloon baseURL:nil];
}

- (void)dealloc
{
    [name release];
    [description release];
    
    [super dealloc];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // first load is about:blank before content is injected
    //
    if ( ! [[[request URL] scheme] isEqualToString:@"about"])
    {
        // we may want to put an alert in here prompting the user first
        //
        [[UIApplication sharedApplication] openURL:[request URL]];
        
        return NO;
    }
    
    return YES;
}

@end