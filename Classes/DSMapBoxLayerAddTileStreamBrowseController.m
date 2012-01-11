//
//  DSMapBoxLayerAddTileStreamBrowseController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "DSMapBoxLayerAddPreviewController.h"
#import "DSMapBoxAlphaModalNavigationController.h"
#import "DSMapBoxTintedBarButtonItem.h"
#import "DSMapBoxErrorView.h"
#import "DSMapBoxTileStreamCommon.h"

#import "JSONKit.h"

#import "RMTile.h"

#import <CoreLocation/CoreLocation.h>

@interface DSMapBoxLayerAddTileStreamBrowseController ()

@property (nonatomic, strong) NSArray *layers;
@property (nonatomic, strong) NSMutableArray *selectedLayers;
@property (nonatomic, strong) NSMutableArray *selectedImages;
@property (nonatomic, strong) NSURLConnection *layersDownload;
@property (nonatomic, strong) UIView *animatedTileView;
@property (nonatomic, assign) CGPoint originalTileViewCenter;
@property (nonatomic, assign) CGSize originalTileViewSize;

@end

#pragma mark -

@implementation DSMapBoxLayerAddTileStreamBrowseController

@synthesize helpLabel;
@synthesize spinner;
@synthesize tileScrollView;
@synthesize tilePageControl;
@synthesize serverName;
@synthesize serverURL;
@synthesize layers;
@synthesize selectedLayers;
@synthesize selectedImages;
@synthesize layersDownload;
@synthesize animatedTileView;
@synthesize originalTileViewCenter;
@synthesize originalTileViewSize;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup state
    //
    self.layers = [NSArray array];
    
    self.selectedLayers = [NSMutableArray array];
    self.selectedImages = [NSMutableArray array];
    
    // setup nav bar
    //
    if ([self.serverName hasPrefix:@"http"])
        self.navigationItem.title = self.serverName;
    
    else
        self.navigationItem.title = [NSString stringWithFormat:@"Browse %@%@ Maps", self.serverName, ([self.serverName hasSuffix:@"s"] ? @"'" : @"'s")];
    
    self.navigationItem.rightBarButtonItem = [[DSMapBoxTintedBarButtonItem alloc] initWithTitle:@"Add Layer" 
                                                                                         target:self 
                                                                                         action:@selector(tappedDoneButton:)];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // setup progress indication
    //
    [self.spinner startAnimating];
    
    self.helpLabel.hidden       = YES;
    self.tileScrollView.hidden  = YES;
    self.tilePageControl.hidden = YES;
    
    // fire off layer list request
    //
    NSString *fullURLString;
    
    if ([[self.serverURL absoluteString] hasPrefix:[DSMapBoxTileStreamCommon serverHostnamePrefix]])
        fullURLString = [NSString stringWithFormat:@"%@%@", self.serverURL, kTileStreamMapAPIPath];

    else
        fullURLString = [NSString stringWithFormat:@"%@%@", self.serverURL, kTileStreamTilesetAPIPath];
    
    DSMapBoxURLRequest *layersRequest = [DSMapBoxURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    layersRequest.timeoutInterval = 10;
    
    self.layersDownload = [NSURLConnection connectionWithRequest:layersRequest];
    
    __weak DSMapBoxLayerAddTileStreamBrowseController *weakSelf = self;
    
    self.layersDownload.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
    {
        [DSMapBoxNetworkActivityIndicator removeJob:connection];
        
        [weakSelf.spinner stopAnimating];
        
        id newLayersReceived = [responseData mutableObjectFromJSONData];
        
        if (newLayersReceived && [newLayersReceived isKindOfClass:[NSMutableArray class]])
        {
            // Grab parsed objects for safekeeping. Previously, accessing the response 
            // objects directly was unreliably available in memory.
            //
            NSMutableArray *newLayers = [NSMutableArray arrayWithArray:[newLayersReceived allObjects]];
            
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
                        [layer setValue:[weakSelf.serverURL scheme]                                                           forKey:@"apiScheme"];
                        [layer setValue:[weakSelf.serverURL host]                                                             forKey:@"apiHostname"];
                        [layer setValue:([weakSelf.serverURL port] ? [weakSelf.serverURL port] : [NSNumber numberWithInt:80]) forKey:@"apiPort"];
                        [layer setValue:([weakSelf.serverURL path] ? [weakSelf.serverURL path] : @"")                         forKey:@"apiPath"];
                        [layer setValue:tileURLString                                                                         forKey:@"tileURL"];
                        
                        // set size for downloadable tiles
                        //
                        [layer setValue:[NSNumber numberWithInt:([[layer objectForKey:@"size"] isKindOfClass:[NSString class]] ? [[layer objectForKey:@"size"] intValue] : 0)] forKey:@"size"];
                        
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
                
                weakSelf.helpLabel.hidden      = NO;
                weakSelf.tileScrollView.hidden = NO;
                
                if ([updatedLayers count] > 9)
                    weakSelf.tilePageControl.hidden = NO;
                
                weakSelf.layers = [NSArray arrayWithArray:updatedLayers];
                
                // layout preview tiles
                //
                int pageCount = ([weakSelf.layers count] / 9) + ([weakSelf.layers count] % 9 ? 1 : 0);
                
                weakSelf.tileScrollView.contentSize = CGSizeMake((weakSelf.tileScrollView.frame.size.width * pageCount), weakSelf.tileScrollView.frame.size.height);
                
                weakSelf.tilePageControl.numberOfPages = pageCount;
                
                for (int i = 0; i < pageCount; i++)
                {
                    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(i * weakSelf.tileScrollView.frame.size.width, 0, weakSelf.tileScrollView.frame.size.width, weakSelf.tileScrollView.frame.size.height)];
                    
                    containerView.backgroundColor = [UIColor clearColor];
                    
                    for (int j = 0; j < 9; j++)
                    {
                        int index = i * 9 + j;
                        
                        if (index < [weakSelf.layers count])
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
                            
                            DSMapBoxLayerAddTileView *tileView = [[DSMapBoxLayerAddTileView alloc] initWithFrame:CGRectMake(x, 105 + (row * 166), 148, 148) 
                                                                                                        imageURL:[imagesToDownload objectAtIndex:index]
                                                                                                       labelText:[[weakSelf.layers objectAtIndex:index] valueForKey:@"name"]];
                            
                            tileView.delegate = weakSelf;
                            tileView.tag = index;
                            
                            [containerView addSubview:tileView];
                        }
                    }
                    
                    [weakSelf.tileScrollView addSubview:containerView];
                }
            }
            else
            {
                DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"No layers available"];
                
                [weakSelf.view addSubview:errorView];
                
                errorView.center = weakSelf.view.center;
            }
        }
        else
        {
            DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to browse"];
            
            [weakSelf.view addSubview:errorView];
            
            errorView.center = weakSelf.view.center;
        }
    };
    
    self.layersDownload.failureBlock = ^(NSURLConnection *connection, NSError *error)
    {
        [DSMapBoxNetworkActivityIndicator removeJob:connection];
        
        [weakSelf.spinner stopAnimating];
        
        DSMapBoxErrorView *errorView = [DSMapBoxErrorView errorViewWithMessage:@"Unable to browse"];
        
        [weakSelf.view addSubview:errorView];
        
        errorView.center = weakSelf.view.center;
    };
    
    [DSMapBoxNetworkActivityIndicator addJob:self.layersDownload];
    
    [self.layersDownload start];
    
    [TESTFLIGHT passCheckpoint:@"browsed TileStream server"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.animatedTileView)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void)
                         {
                             self.animatedTileView.transform = CGAffineTransformScale(self.animatedTileView.transform, self.originalTileViewSize.width / self.animatedTileView.frame.size.width, self.originalTileViewSize.height / self.animatedTileView.frame.size.height);
                             self.animatedTileView.center    = self.originalTileViewCenter;
                             self.animatedTileView.alpha     = 1.0;
                         }
                         completion:^(BOOL finished)
                         {
                             self.animatedTileView = nil;
                         }];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [DSMapBoxNetworkActivityIndicator removeJob:self.layersDownload];
    [self.layersDownload cancel];
}

#pragma mark -

- (void)tappedDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxLayersAdded 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.selectedLayers, @"selectedLayers",
                                                                                                          self.selectedImages, @"selectedImages", 
                                                                                                          nil]];
}

#pragma mark -

- (void)tileView:(DSMapBoxLayerAddTileView *)tileView selectionDidChange:(BOOL)selected
{
    // get layer & image in question
    //
    NSDictionary *layer = [self.layers objectAtIndex:tileView.tag];
    UIImage *layerImage = tileView.image;
    
    // update selection
    //
    if ([self.selectedLayers containsObject:layer])
    {
        [self.selectedLayers removeObject:layer];
        [self.selectedImages removeObject:layerImage];
    }
    else
    {
        [self.selectedLayers addObject:layer];
        [self.selectedImages addObject:layerImage];
    }
    
    // enable/disable action button
    //
    if ([self.selectedLayers count])
        self.navigationItem.rightBarButtonItem.enabled = YES;
    
    else
        self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // modify action button title
    //
    if ([self.selectedLayers count] > 1)
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Add %i Layers", [self.selectedLayers count]];
    
    else
        self.navigationItem.rightBarButtonItem.title = @"Add Layer";
}

- (void)tileViewWantsToShowPreview:(DSMapBoxLayerAddTileView *)tileView
{
    // tapped on top-right "preview" corner; animate
    //
    self.animatedTileView       = tileView;
    self.originalTileViewCenter = tileView.center;
    self.originalTileViewSize   = tileView.frame.size;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.5];
    
    tileView.transform = CGAffineTransformMakeScale(self.originalTileViewSize.width / tileView.frame.size.width * 8.0, self.originalTileViewSize.height / tileView.frame.size.height * 8.0);
    tileView.center    = self.view.center;
    tileView.alpha     = 0.0;
    
    [UIView commitAnimations];
    
    // display preview partway through
    //
    dispatch_delayed_ui_action(0.25, ^(void)
    {
        DSMapBoxLayerAddPreviewController *preview = [[DSMapBoxLayerAddPreviewController alloc] initWithNibName:nil bundle:nil];                         
        
        NSDictionary *layer = [self.layers objectAtIndex:tileView.tag];
        
        preview.info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [layer objectForKey:@"tileURL"], @"tileURL",
                           ([layer objectForKey:@"gridURL"] ? [layer objectForKey:@"gridURL"] : @""), @"gridURL",
                           ([layer objectForKey:@"template"] ? [layer objectForKey:@"template"] : @""), @"template",
                           ([layer objectForKey:@"formatter"] ? [layer objectForKey:@"formatter"] : @""), @"formatter",
                           ([layer objectForKey:@"legend"] ? [layer objectForKey:@"legend"] : @""), @"legend",
                           ([layer objectForKey:@"download"] ? [layer objectForKey:@"download"] : @""), @"download",
                           ([layer objectForKey:@"filesize"] ? [layer objectForKey:@"filesize"] : @""), @"filesize",
                           [NSNumber numberWithInt:[[layer objectForKey:@"minzoom"] intValue]], @"minzoom", 
                           [NSNumber numberWithInt:[[layer objectForKey:@"maxzoom"] intValue]], @"maxzoom", 
                           [layer objectForKey:@"id"], @"id", 
                           [layer objectForKey:@"name"], @"name", 
                           [layer objectForKey:@"center"], @"center",
                           [[layer objectForKey:@"bounds"] componentsJoinedByString:@","], @"bounds",
                           nil];
        
        DSMapBoxAlphaModalNavigationController *wrapper = [[DSMapBoxAlphaModalNavigationController alloc] initWithRootViewController:preview];
        
        wrapper.navigationBar.translucent = YES;
        
        wrapper.modalPresentationStyle = UIModalPresentationFullScreen;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
        
        [self presentModalViewController:wrapper animated:YES];
    });
}

#pragma mark -

// TODO: if scrolling too fast, doesn't update
//
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.tilePageControl.currentPage = (int)floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
}

@end