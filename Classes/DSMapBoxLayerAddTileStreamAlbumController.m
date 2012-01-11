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
#import "DSMapBoxTileStreamCommon.h"

#import "JSONKit.h"

@interface DSMapBoxLayerAddTileStreamAlbumController ()

@property (nonatomic, strong) NSURLConnection *albumDownload;
@property (nonatomic, strong) NSArray *servers;

@end

#pragma mark -

@implementation DSMapBoxLayerAddTileStreamAlbumController

@synthesize helpLabel;
@synthesize spinner;
@synthesize accountScrollView;
@synthesize accountPageControl;
@synthesize albumDownload;
@synthesize servers;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup state
    //
    self.servers = [NSArray array];
    
    // setup nav bar
    //
    self.navigationItem.title = @"Choose Hosting Account";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Choose Account"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil 
                                                                            action:nil];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                          target:self
                                                                                          action:@selector(dismissModal)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"More Options"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(tappedCustomButton:)];

    // setup progress indication
    //
    [self.spinner startAnimating];
    
    self.helpLabel.hidden          = YES;
    self.accountScrollView.hidden  = YES;
    self.accountPageControl.hidden = YES;
    
    // fire off account list request
    //
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@", [DSMapBoxTileStreamCommon serverHostnamePrefix], kTileStreamAlbumAPIPath];
    
    DSMapBoxURLRequest *albumRequest = [DSMapBoxURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    albumRequest.timeoutInterval = 10;
    
    self.albumDownload = [NSURLConnection connectionWithRequest:albumRequest];
    
    __weak DSMapBoxLayerAddTileStreamAlbumController *weakSelf = self;
    
    self.albumDownload.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
    {
        [DSMapBoxNetworkActivityIndicator removeJob:connection];
        
        [weakSelf.spinner stopAnimating];
        
        id newServersReceived = [responseData mutableObjectFromJSONData];
        
        if (newServersReceived && [newServersReceived isKindOfClass:[NSMutableArray class]])
        {
            // Grab parsed objects for safekeeping. Previously, accessing the response 
            // objects directly was unreliably available in memory.
            //
            NSMutableArray *newServers = [NSMutableArray arrayWithArray:[newServersReceived allObjects]];
            
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
            weakSelf.helpLabel.hidden         = NO;
            weakSelf.accountScrollView.hidden = NO;
            
            if ([newServers count] > 9)
                weakSelf.accountPageControl.hidden = NO;
            
            // update content
            //
            weakSelf.servers = [NSArray arrayWithArray:newServers];
            
            // layout preview tiles
            //
            int pageCount = ([weakSelf.servers count] / 9) + ([weakSelf.servers count] % 9 ? 1 : 0);
            
            weakSelf.accountScrollView.contentSize = CGSizeMake((weakSelf.accountScrollView.frame.size.width * pageCount), weakSelf.accountScrollView.frame.size.height);
            
            weakSelf.accountPageControl.numberOfPages = pageCount;
            
            for (int i = 0; i < pageCount; i++)
            {
                UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(i * weakSelf.accountScrollView.frame.size.width, 0, weakSelf.accountScrollView.frame.size.width, weakSelf.accountScrollView.frame.size.height)];
                
                containerView.backgroundColor = [UIColor clearColor];
                
                for (int j = 0; j < 9; j++)
                {
                    int index = i * 9 + j;
                    
                    if (index < [weakSelf.servers count])
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
                        NSDictionary *server  = [weakSelf.servers objectAtIndex:index];
                        NSString *accountName = ([[server objectForKey:@"name"] length] ? [server objectForKey:@"name"] : [server objectForKey:@"id"]);
                        NSString *layerCount  = [server valueForKey:@"mapCount"];
                        
                        DSMapBoxLayerAddAccountView *accountView = [[DSMapBoxLayerAddAccountView alloc] initWithFrame:CGRectMake(x, 105 + (row * 166), 148, 148) 
                                                                                                            imageURLs:[imagesToDownload objectAtIndex:index]
                                                                                                            labelText:[NSString stringWithFormat:@"%@ (%@)", accountName, layerCount]];
                        
                        accountView.delegate = weakSelf;
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
                
                [weakSelf.accountScrollView addSubview:containerView];
            }
        }
    };
    
    self.albumDownload.failureBlock = ^(NSURLConnection *connection, NSError *error)
    {
        [DSMapBoxNetworkActivityIndicator removeJob:connection];
        
        [weakSelf.spinner stopAnimating];
        
        DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to connect"];
        
        [weakSelf.view addSubview:errorView];
        
        errorView.center = weakSelf.view.center;
    };
    
    [DSMapBoxNetworkActivityIndicator addJob:self.albumDownload];

    [self.albumDownload start];
    
    [TESTFLIGHT passCheckpoint:@"browsed TileStream accounts"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [DSMapBoxNetworkActivityIndicator removeJob:self.albumDownload];
    [self.albumDownload cancel];
}

#pragma mark -

- (void)tappedCustomButton:(id)sender
{
    DSMapBoxLayerAddCustomServerController *customController = [[DSMapBoxLayerAddCustomServerController alloc] initWithNibName:nil bundle:nil];
    
    [(UINavigationController *)self.parentViewController pushViewController:customController animated:YES];
}

- (void)dismissModal
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)accountViewWasSelected:(DSMapBoxLayerAddAccountView *)accountView
{
    NSDictionary *account = [self.servers objectAtIndex:accountView.tag];
    
    NSString *serverURLString = [NSString stringWithFormat:@"%@/%@", [DSMapBoxTileStreamCommon serverHostnamePrefix], [account valueForKey:@"id"]];
    
    DSMapBoxLayerAddTileStreamBrowseController *browseController = [[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil];
    
    browseController.serverName = ([[account objectForKey:@"name"] length] ? [account objectForKey:@"name"] : [account objectForKey:@"id"]);
    browseController.serverURL  = [NSURL URLWithString:serverURLString];
    
    [(UINavigationController *)self.parentViewController pushViewController:browseController animated:YES];
}

#pragma mark -

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.accountPageControl.currentPage = (int)floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
}

@end