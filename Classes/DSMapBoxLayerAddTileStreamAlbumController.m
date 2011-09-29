//
//  DSMapBoxLayerAddTileStreamAlbumController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamAlbumController.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"
#import "DSMapBoxLayerAddCustomServerController.h"
#import "DSMapBoxErrorView.h"

#import "ASIHTTPRequest.h"

#import "JSONKit.h"

@implementation DSMapBoxLayerAddTileStreamAlbumController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup state
    //
    servers = [[NSArray array] retain];
    
    // setup nav bar
    //
    self.navigationItem.title = @"Choose Hosting Account";
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Choose Account"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil 
                                                                             action:nil] autorelease];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                           target:self
                                                                                           action:@selector(dismissModal)] autorelease];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"More Options"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(tappedCustomButton:)] autorelease];

    // setup progress indication
    //
    [spinner startAnimating];
    
    helpLabel.hidden          = YES;
    accountScrollView.hidden  = YES;
    accountPageControl.hidden = YES;
    
    // fire off account list request
    //
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@", kTileStreamHostingURL, kTileStreamAlbumAPIPath];
    
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];

    albumRequest = [[ASIHTTPRequest requestWithURL:[NSURL URLWithString:fullURLString]] retain];
    
    albumRequest.timeOutSeconds = 10;
    albumRequest.delegate = self;

    [albumRequest startAsynchronous];
    
    [TESTFLIGHT passCheckpoint:@"browsed TileStream accounts"];
}

- (void)dealloc
{
    [servers release];
    
    [albumRequest clearDelegatesAndCancel];
    [albumRequest release];
    
    [super dealloc];
}

#pragma mark -

- (void)tappedCustomButton:(id)sender
{
    DSMapBoxLayerAddCustomServerController *customController = [[[DSMapBoxLayerAddCustomServerController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    [(UINavigationController *)self.parentViewController pushViewController:customController animated:YES];
}

- (void)dismissModal
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)accountViewWasSelected:(DSMapBoxLayerAddAccountView *)accountView
{
    NSDictionary *account = [servers objectAtIndex:accountView.tag];
    
    NSString *serverURLString = [NSString stringWithFormat:@"%@/%@", kTileStreamHostingURL, [account valueForKey:@"id"]];
    
    DSMapBoxLayerAddTileStreamBrowseController *browseController = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    browseController.serverName = ([account objectForKey:@"name"] ? [account objectForKey:@"name"] : [account objectForKey:@"id"]);
    browseController.serverURL  = [NSURL URLWithString:serverURLString];
    
    [(UINavigationController *)self.parentViewController pushViewController:browseController animated:YES];
}

#pragma mark -

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];
    
    DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to connect"];
    
    [self.view addSubview:errorView];
    
    errorView.center = self.view.center;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];
    
    id newServers = [request.responseData mutableObjectFromJSONData];
    
    if (newServers && [newServers isKindOfClass:[NSMutableArray class]])
    {
        // filter out empty accounts
        //
        [newServers filterUsingPredicate:[NSPredicate predicateWithFormat:@"thumbs.@count > 0"]];
        
        // filter out MapBox default
        //
        NSDictionary *defaultAccount = [[newServers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id = %@", kTileStreamDefaultAccount]] objectAtIndex:0];
        
        [newServers filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", defaultAccount]];
        
        // re-add default at start
        //
        [newServers insertObject:defaultAccount atIndex:0];
        
        // queue up images
        //
        NSMutableArray *imagesToDownload = [NSMutableArray array];
        
        for (int i = 0; i < [newServers count]; i++)
        {
            NSMutableDictionary *server = [NSMutableDictionary dictionaryWithDictionary:[newServers objectAtIndex:i]];

            NSMutableArray *thumbURLs = [NSMutableArray array];
            
            // don't queue up null thumbs
            //
            for (id thumbURLString in [server objectForKey:@"thumbs"])
                if ([thumbURLString isKindOfClass:[NSString class]] && [(NSString *)thumbURLString length])
                    [thumbURLs addObject:[NSURL URLWithString:thumbURLString]];
            
            [imagesToDownload addObject:thumbURLs];
        }
        
        // filter out servers with all null thumbs
        //
        for (NSMutableDictionary *newServer in [NSArray arrayWithArray:newServers])
        {
            [[newServer objectForKey:@"thumbs"] filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF isKindOfClass:%@ AND SELF.length > 0", [NSString class]]];
            
            if ( ! [[newServer objectForKey:@"thumbs"] count])
                [newServers removeObject:newServer];
        }
        
        // make things visible
        //
        helpLabel.hidden         = NO;
        accountScrollView.hidden = NO;
        
        if ([newServers count] > 9)
            accountPageControl.hidden = NO;

        // update content
        //
        [servers release];
        
        servers = [[NSArray arrayWithArray:newServers] retain];
        
        // layout preview tiles
        //
        int pageCount = ([servers count] / 9) + ([servers count] % 9 ? 1 : 0);
        
        accountScrollView.contentSize = CGSizeMake((accountScrollView.frame.size.width * pageCount), accountScrollView.frame.size.height);

        accountPageControl.numberOfPages = pageCount;

        for (int i = 0; i < pageCount; i++)
        {
            UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(i * accountScrollView.frame.size.width, 0, accountScrollView.frame.size.width, accountScrollView.frame.size.height)] autorelease];
            
            containerView.backgroundColor = [UIColor clearColor];
            
            for (int j = 0; j < 9; j++)
            {
                int index = i * 9 + j;
                
                if (index < [servers count])
                {
                    int row = j / 3;
                    int col = j - (row * 3);

                    CGFloat x;
                    
                    if (col == 0)
                        x = 32;
                    
                    else if (col == 1)
                        x = containerView.frame.size.width / 2 - 74;
                    
                    else if (col == 2)
                        x = containerView.frame.size.width - 148 - 32;
                    
                    // get label bits
                    //
                    NSDictionary *server  = [servers objectAtIndex:index];
                    NSString *accountName = ([server objectForKey:@"name"] ? [server objectForKey:@"name"] : [server objectForKey:@"id"]);
                    NSString *layerCount  = [server valueForKey:@"mapCount"];

                    DSMapBoxLayerAddAccountView *accountView = [[[DSMapBoxLayerAddAccountView alloc] initWithFrame:CGRectMake(x, 105 + (row * 166), 148, 148) 
                                                                                                         imageURLs:[imagesToDownload objectAtIndex:index]
                                                                                                         labelText:[NSString stringWithFormat:@"%@ (%@)", accountName, layerCount]] autorelease];
                    
                    accountView.delegate = self;
                    accountView.tag = index;
                    
                    if (i == 0 && index == 0)
                        accountView.featured = YES;
                    
                    if (i == 0)
                    {
                        // slide-fade-animate in first page of results
                        //
                        CGRect destRect = accountView.frame;
                        
                        accountView.frame = CGRectMake(accountView.frame.origin.x - 500, 
                                                       accountView.frame.origin.y, 
                                                       accountView.frame.size.width, 
                                                       accountView.frame.size.height);
                        
                        accountView.alpha = 0.0;
                        
                        [UIView beginAnimations:nil context:nil];
                        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                        [UIView setAnimationDuration:0.25];
                        [UIView setAnimationDelay:(0.05 + index * 0.05)];
                        
                        accountView.frame = destRect;
                        accountView.alpha = 1.0;
                        
                        [UIView commitAnimations];
                    }
                    
                    [containerView addSubview:accountView];
                }
            }
                        
            [accountScrollView addSubview:containerView];
        }
    }
}

#pragma mark -

// TODO: if scrolling too fast, doesn't update
//
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    accountPageControl.currentPage = (int)floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
}

@end