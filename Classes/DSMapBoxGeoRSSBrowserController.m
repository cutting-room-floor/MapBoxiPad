//
//  DSMapBoxGeoRSSBrowserController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/7/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxGeoRSSBrowserController.h"

#define kBrowserStartURL @"http://reliefweb.managingnews.com/feeds"

@implementation DSMapBoxGeoRSSBrowserController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kBrowserStartURL]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [browserURLString release];
    
    [super dealloc];
}

#pragma mark -

- (IBAction)tappedBackButton:(id)sender
{
    [webView stopLoading];
    [webView goBack];
}

- (IBAction)tappedCancel:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ( ! [textField.text hasPrefix:@"http://"] && ! [textField.text hasPrefix:@"https://"])
        textField.text = [NSString stringWithFormat:@"http://%@", textField.text];
    
    NSURL *requestURL = [NSURL URLWithString:textField.text];
    
    if (requestURL)
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:textField.text]]];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] path] hasSuffix:@".xml"] || [[[request URL] path] hasSuffix:@".rss"])
    {
        if (self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(browserController:didVisitFeedURL:)])
            [self.delegate browserController:self didVisitFeedURL:[request URL]];
        
        [self tappedCancel:self];
        
        return NO;
    }
    
    else if ([[[request URL] scheme] hasPrefix:@"http"])
    {
        NSString *contents = [NSString stringWithContentsOfURL:[request URL] encoding:NSUTF8StringEncoding error:NULL];
        
        if ([contents hasPrefix:@"<?xml "])
        {
            if (self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(browserController:didVisitFeedURL:)])
                [self.delegate browserController:self didVisitFeedURL:[request URL]];
            
            [self tappedCancel:self];
            
            return NO;
        }

        [browserURLString release];
        browserURLString = [[[request URL] absoluteString] retain];

        return YES;
    }
    
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    addressField.text = browserURLString;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    addressField.text = browserURLString;
}

@end