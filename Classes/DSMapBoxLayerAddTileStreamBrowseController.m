//
//  DSMapBoxLayerAddTileStreamBrowseController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "MapBoxConstants.h"

#import "DSMapBoxLayerAddPreviewController.h"
#import "DSMapBoxAlphaModalNavigationController.h"
#import "DSMapBoxTintedBarButtonItem.h"
#import "DSMapBoxErrorView.h"

#import "ASIHTTPRequest.h"

#import "JSONKit.h"

#import "RMTile.h"

#import <CoreLocation/CoreLocation.h>

NSString *const DSMapBoxLayersAdded = @"DSMapBoxLayersAdded";

@implementation DSMapBoxLayerAddTileStreamBrowseController

@synthesize serverName;
@synthesize serverURL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup state
    //
    layers = [[NSArray array] retain];
    
    selectedLayers = [[NSMutableArray array] retain];
    selectedImages = [[NSMutableArray array] retain];
    
    // setup nav bar
    //
    if ([self.serverName hasPrefix:@"http"])
        self.navigationItem.title = self.serverName;
    
    else
        self.navigationItem.title = [NSString stringWithFormat:@"Browse %@%@ Tiles", self.serverName, ([self.serverName hasSuffix:@"s"] ? @"'" : @"'s")];
    
    self.navigationItem.rightBarButtonItem = [[[DSMapBoxTintedBarButtonItem alloc] initWithTitle:@"Add Layer" 
                                                                                          target:self 
                                                                                          action:@selector(tappedDoneButton:)] autorelease];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // setup progress indication
    //
    [spinner startAnimating];
    
    helpLabel.hidden       = YES;
    tileScrollView.hidden  = YES;
    tilePageControl.hidden = YES;
    
    // fire off layer list request
    //
    NSString *fullURLString;
    
    if ([[self.serverURL absoluteString] hasPrefix:kTileStreamHostingURL])
        fullURLString = [NSString stringWithFormat:@"%@%@", self.serverURL, kTileStreamMapAPIPath];

    else
        fullURLString = [NSString stringWithFormat:@"%@%@", self.serverURL, kTileStreamTilesetAPIPath];
    
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
    
    layersRequest = [[ASIHTTPRequest requestWithURL:[NSURL URLWithString:fullURLString]] retain];
    
    layersRequest.timeOutSeconds = 10;
    layersRequest.delegate = self;
    
    [layersRequest startAsynchronous];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (animatedTileView)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void)
                         {
                             animatedTileView.transform = CGAffineTransformScale(animatedTileView.transform, 1 / 8.0, 1 / 8.0);
                             animatedTileView.center    = originalTileViewCenter;
                             animatedTileView.alpha     = 1.0;
                         }
                         completion:^(BOOL finished)
                         {
                             [animatedTileView release];
                             animatedTileView = nil;
                         }];
    }
}

- (void)dealloc
{
    [layers release];
    [selectedLayers release];
    [selectedImages release];

    [serverName release];
    [serverURL release];
    
    [layersRequest clearDelegatesAndCancel];
    [layersRequest release];
    
    [super dealloc];
}


#pragma mark -

- (void)tappedDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxLayersAdded 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:selectedLayers, @"selectedLayers",
                                                                                                          selectedImages, @"selectedImages", 
                                                                                                          nil]];
}

#pragma mark -

- (void)tileView:(DSMapBoxLayerAddTileView *)tileView selectionDidChange:(BOOL)selected
{
    // get layer & image in question
    //
    NSDictionary *layer = [layers objectAtIndex:tileView.tag];
    UIImage *layerImage = tileView.image;
    
    // update selection
    //
    if ([selectedLayers containsObject:layer])
    {
        [selectedLayers removeObject:layer];
        [selectedImages removeObject:layerImage];
    }
    else
    {
        [selectedLayers addObject:layer];
        [selectedImages addObject:layerImage];
    }
    
    // enable/disable action button
    //
    if ([selectedLayers count])
        self.navigationItem.rightBarButtonItem.enabled = YES;
    
    else
        self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // modify action button title
    //
    if ([selectedLayers count] > 1)
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Add %i Layers", [selectedLayers count]];
    
    else
        self.navigationItem.rightBarButtonItem.title = @"Add Layer";
}

- (void)tileViewWantsToShowPreview:(DSMapBoxLayerAddTileView *)tileView
{
    // tapped on top-right "preview" corner; animate
    //
    animatedTileView       = [tileView retain];
    originalTileViewCenter = animatedTileView.center;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.5];
    
    tileView.transform = CGAffineTransformMakeScale(8.0, 8.0);
    tileView.center    = self.view.center;
    tileView.alpha     = 0.0;
    
    [UIView commitAnimations];
    
    // display preview partway through
    //
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
    {
        DSMapBoxLayerAddPreviewController *preview = [[[DSMapBoxLayerAddPreviewController alloc] initWithNibName:nil bundle:nil] autorelease];                         
        
        NSDictionary *layer = [layers objectAtIndex:tileView.tag];
        
        preview.info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [layer objectForKey:@"tileURL"], @"tileURL",
                           ([layer objectForKey:@"gridURL"] ? [layer objectForKey:@"gridURL"] : @""), @"gridURL",
                           ([layer objectForKey:@"formatter"] ? [layer objectForKey:@"formatter"] : @""), @"formatter",
                           [NSNumber numberWithInt:[[layer objectForKey:@"minzoom"] intValue]], @"minzoom", 
                           [NSNumber numberWithInt:[[layer objectForKey:@"maxzoom"] intValue]], @"maxzoom", 
                           [layer objectForKey:@"id"], @"id", 
                           [layer objectForKey:@"version"], @"version", 
                           [layer objectForKey:@"name"], @"name", 
                           [layer objectForKey:@"description"], @"description", 
                           [layer objectForKey:@"center"], @"center",
                           [layer objectForKey:@"type"], @"type",
                           [[layer objectForKey:@"bounds"] componentsJoinedByString:@","], @"bounds",
                           nil];
        
        DSMapBoxAlphaModalNavigationController *wrapper = [[[DSMapBoxAlphaModalNavigationController alloc] initWithRootViewController:preview] autorelease];
        
        wrapper.navigationBar.translucent = YES;
        
        wrapper.modalPresentationStyle = UIModalPresentationFullScreen;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
        
        [self presentModalViewController:wrapper animated:YES];
    });
}

#pragma mark -

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];
    
    DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to browse TileStream"];
    
    [self.view addSubview:errorView];
    
    errorView.center = self.view.center;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];
    
    id newLayers = [request.responseData mutableObjectFromJSONData];

    if (newLayers && [newLayers isKindOfClass:[NSMutableArray class]])
    {
        if ([newLayers count])
        {
            NSMutableArray *updatedLayers    = [NSMutableArray array];
            NSMutableArray *imagesToDownload = [NSMutableArray array];
            
            for (int i = 0; i < [newLayers count]; i++)
            {
                NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithDictionary:[newLayers objectAtIndex:i]];
                
                // determine center tile to download
                //
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[[layer objectForKey:@"center"] objectAtIndex:1] floatValue], 
                                                                           [[[layer objectForKey:@"center"] objectAtIndex:0] floatValue]);
                
                int tileZoom = [[[layer objectForKey:@"center"] objectAtIndex:2] intValue];
                
                int tileX = (int)(floor((center.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
                int tileY = (int)(floor((1.0 - log(tan(center.latitude * M_PI / 180.0) + 1.0 / \
                                                   cos(center.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
                
                tileY = pow(2.0, tileZoom) - tileY - 1.0;
                
                RMTile tile = {
                    .zoom = tileZoom,
                    .x    = tileX,
                    .y    = tileY,
                };
                
                if ([layer objectForKey:@"tiles"] && [[layer objectForKey:@"tiles"] isKindOfClass:[NSArray class]])
                {
                    NSString *tileURLString = [[layer objectForKey:@"tiles"] objectAtIndex:0];
                    
                    // update layer for server-wide variables
                    //
                    [layer setValue:[self.serverURL scheme]                                                       forKey:@"apiScheme"];
                    [layer setValue:[self.serverURL host]                                                         forKey:@"apiHostname"];
                    [layer setValue:([self.serverURL port] ? [self.serverURL port] : [NSNumber numberWithInt:80]) forKey:@"apiPort"];
                    [layer setValue:([self.serverURL path] ? [self.serverURL path] : @"")                         forKey:@"apiPath"];
                    [layer setValue:tileURLString                                                                 forKey:@"tileURL"];

                    // handle null that needs to be serialized later
                    //
                    // see https://github.com/developmentseed/tilestream-pro/issues/230
                    //
                    for (NSString *key in [layer allKeys])
                        if ([[layer objectForKey:key] isKindOfClass:[NSNull class]])
                            [layer setObject:@"" forKey:key];
                    
                    // pull out first grid URL
                    //
                    if ([layer objectForKey:@"grids"] && [[layer objectForKey:@"grids"] isKindOfClass:[NSArray class]])
                        [layer setValue:[[layer objectForKey:@"grids"] objectAtIndex:0] forKey:@"gridURL"];
                    
                    // swap in x/y/z
                    //
                    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{z}" withString:[NSString stringWithFormat:@"%d", tile.zoom]];
                    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{x}" withString:[NSString stringWithFormat:@"%d", tile.x]];
                    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{y}" withString:[NSString stringWithFormat:@"%d", tile.y]];

                    // queue up center tile download
                    //
                    [imagesToDownload addObject:[NSURL URLWithString:tileURLString]];
                }
                else
                {
                    [imagesToDownload addObject:[NSNull null]];
                }

                [updatedLayers addObject:layer];
            }
            
            helpLabel.hidden       = NO;
            tileScrollView.hidden  = NO;
            
            if ([updatedLayers count] > 9)
                tilePageControl.hidden = NO;

            [layers release];
            
            layers = [[NSArray arrayWithArray:updatedLayers] retain];
            
            // layout preview tiles
            //
            int pageCount = ([layers count] / 9) + ([layers count] % 9 ? 1 : 0);
            
            tileScrollView.contentSize = CGSizeMake((tileScrollView.frame.size.width * pageCount), tileScrollView.frame.size.height);
            
            tilePageControl.numberOfPages = pageCount;
            
            for (int i = 0; i < pageCount; i++)
            {
                UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(i * tileScrollView.frame.size.width, 0, tileScrollView.frame.size.width, tileScrollView.frame.size.height)] autorelease];
                
                containerView.backgroundColor = [UIColor clearColor];
                
                for (int j = 0; j < 9; j++)
                {
                    int index = i * 9 + j;
                    
                    if (index < [layers count])
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
                        
                        DSMapBoxLayerAddTileView *tileView = [[[DSMapBoxLayerAddTileView alloc] initWithFrame:CGRectMake(x, 105 + (row * 166), 148, 148) 
                                                                                                     imageURL:[imagesToDownload objectAtIndex:index]
                                                                                                    labelText:[[layers objectAtIndex:index] valueForKey:@"name"]] autorelease];
                        
                        tileView.delegate = self;
                        tileView.tag = index;
                        
                        [containerView addSubview:tileView];
                    }
                }
                
                [tileScrollView addSubview:containerView];
            }
        }
        else
        {
            DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"TileStream has no layers"];
            
            [self.view addSubview:errorView];
            
            errorView.center = self.view.center;
        }
    }
    else
    {
        DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to browse TileStream"];
        
        [self.view addSubview:errorView];
        
        errorView.center = self.view.center;
    }
}

#pragma mark -

// TODO: if scrolling too fast, doesn't update
//
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    tilePageControl.currentPage = (int)floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
}

@end