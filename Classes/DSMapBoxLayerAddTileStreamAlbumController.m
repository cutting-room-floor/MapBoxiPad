//
//  DSMapBoxLayerAddTileStreamAlbumController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/11/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamAlbumController.h"

#import "MapBoxConstants.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"
#import "DSMapBoxLayerAddTypeController.h"

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
    self.navigationItem.title = @"Choose TileStream Server";
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Choose Server"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:nil
                                                                             action:nil] autorelease];

    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                           target:self.parentViewController
                                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Custom"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(tappedAddButton:)] autorelease];

    // setup progress indication
    //
    [spinner startAnimating];
    
    helpLabel.hidden          = YES;
    accountScrollView.hidden  = YES;
    accountPageControl.hidden = YES;
    
    // fire off account list request
    //
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@", kTileStreamHostingURL, kTileStreamAlbumAPIPath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)dealloc
{
    [servers release];
    
    [super dealloc];
}

#pragma mark -

- (void)tappedAddButton:(id)sender
{
    DSMapBoxLayerAddTypeController *typeController = [[[DSMapBoxLayerAddTypeController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    [(UINavigationController *)self.parentViewController pushViewController:typeController animated:YES];
}

#pragma mark -

- (void)accountViewWasSelected:(DSMapBoxLayerAddAccountView *)accountView
{
    NSDictionary *account = [servers objectAtIndex:accountView.tag];
    
    NSString *serverURLString = [NSString stringWithFormat:@"%@/%@", kTileStreamHostingURL, [account valueForKey:@"id"]];
    
    DSMapBoxLayerAddTileStreamBrowseController *browseController = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    browseController.serverName = [account valueForKey:@"id"];
    browseController.serverURL  = [NSURL URLWithString:serverURLString];
    
    [(UINavigationController *)self.parentViewController pushViewController:browseController animated:YES];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // TODO: detect if offline and/or retry
    //
    NSLog(@"%@", error);
    
    [spinner stopAnimating];
    
    [connection autorelease];
    
    [receivedData release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [spinner stopAnimating];
    
    [connection autorelease];
    
    id newServers = [receivedData mutableObjectFromJSONData];
    
    [receivedData release];
    
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
        
        // make things visible
        //
        helpLabel.hidden         = NO;
        accountScrollView.hidden = NO;
        
        // queue up images
        //
        NSMutableArray *imagesToDownload = [NSMutableArray array];
        
        for (int i = 0; i < [newServers count]; i++)
        {
            NSMutableDictionary *server = [NSMutableDictionary dictionaryWithDictionary:[newServers objectAtIndex:i]];

            [imagesToDownload addObject:[NSURL URLWithString:[[server objectForKey:@"thumbs"] objectAtIndex:0]]];
        }
        
        // update content
        //
        [servers release];
        
        servers = [[NSArray arrayWithArray:newServers] retain];
        
        // layout preview tiles
        //
        int pageCount = ([servers count] / 9) + 1;
        
        accountPageControl.numberOfPages = pageCount;
        
        if ([newServers count] > 9)
            accountPageControl.hidden = NO;

        else
            accountPageControl.hidden = YES;
        
        accountScrollView.contentSize = CGSizeMake((accountScrollView.frame.size.width * pageCount), accountScrollView.frame.size.height);
        
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
                        x = 10;
                    
                    else if (col == 1)
                        x = containerView.frame.size.width / 2 - 74;
                    
                    else if (col == 2)
                        x = containerView.frame.size.width - 148 - 10;
                    
                    // get label bits
                    //
                    NSString *accountName = [[servers objectAtIndex:index] valueForKey:@"id"];
                    NSString *layerCount  = [[[servers objectAtIndex:index] valueForKey:@"quota"] valueForKey:@"count"];

                    DSMapBoxLayerAddAccountView *accountView = [[[DSMapBoxLayerAddAccountView alloc] initWithFrame:CGRectMake(x, row * 168, 148, 148) 
                                                                                                          imageURL:[imagesToDownload objectAtIndex:index]
                                                                                                         labelText:[NSString stringWithFormat:@"%@ (%@)", accountName, layerCount]] autorelease];
                    
                    accountView.delegate = self;
                    accountView.tag = index;
                    
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