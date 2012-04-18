//
//  DSMapBoxLayerAddTileStreamBrowseController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "DSMapBoxLayerAddPreviewController.h"
#import "DSMapBoxStyledModalNavigationController.h"
#import "DSMapBoxErrorView.h"
#import "DSMapBoxTileStreamCommon.h"

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Layer"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(tappedDoneButton:)
                                                                          tintColor:kMapBoxBlue];
    self.navigationItem.rightBarButtonItem.enabled   = NO;
    
    // setup progress indication
    //
    [self.spinner startAnimating];
    
    self.helpLabel.hidden       = YES;
    self.tileScrollView.hidden  = YES;
    
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
        
        id newLayersReceived = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
        
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
                    NSMutableDictionary *layerInfo = [NSMutableDictionary dictionaryWithDictionary:[newLayers objectAtIndex:i]];
                    
                    // determine center tile to download
                    //
                    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[[layerInfo objectForKey:@"center"] objectAtIndex:1] floatValue], 
                                                                               [[[layerInfo objectForKey:@"center"] objectAtIndex:0] floatValue]);
                    
                    int tileZoom = [[[layerInfo objectForKey:@"center"] objectAtIndex:2] intValue];
                    
                    int tileX = (int)(floor((center.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
                    int tileY = (int)(floor((1.0 - log(tan(center.latitude * M_PI / 180.0) + 1.0 / \
                                                       cos(center.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
                    
                    tileY = pow(2.0, tileZoom) - tileY - 1.0;
                    
                    RMTile tile = {
                        .zoom = tileZoom,
                        .x    = tileX,
                        .y    = tileY,
                    };
                    
                    if ([layerInfo objectForKey:@"tiles"] && [[layerInfo objectForKey:@"tiles"] isKindOfClass:[NSArray class]])
                    {
                        NSString *tileURLString = [[layerInfo objectForKey:@"tiles"] objectAtIndex:0];
                        
                        // update layer for server-wide variables
                        //
                        [layerInfo setValue:[weakSelf.serverURL scheme]                                                           forKey:@"apiScheme"];
                        [layerInfo setValue:[weakSelf.serverURL host]                                                             forKey:@"apiHostname"];
                        [layerInfo setValue:([weakSelf.serverURL port] ? [weakSelf.serverURL port] : [NSNumber numberWithInt:80]) forKey:@"apiPort"];
                        [layerInfo setValue:([weakSelf.serverURL path] ? [weakSelf.serverURL path] : @"")                         forKey:@"apiPath"];
                        [layerInfo setValue:tileURLString                                                                         forKey:@"tileURL"];
                        
                        // set size for downloadable tiles
                        //
                        [layerInfo setValue:[NSNumber numberWithInt:([[layerInfo objectForKey:@"size"] isKindOfClass:[NSString class]] ? [[layerInfo objectForKey:@"size"] intValue] : 0)] forKey:@"size"];
                        
                        // handle null that needs to be serialized later
                        //
                        // see https://github.com/developmentseed/tilestream-pro/issues/230
                        //
                        for (NSString *key in [layerInfo allKeys])
                            if ([[layerInfo objectForKey:key] isKindOfClass:[NSNull class]])
                                [layerInfo setObject:@"" forKey:key];
                        
                        // pull out first grid URL
                        //
                        if ([layerInfo objectForKey:@"grids"] && [[layerInfo objectForKey:@"grids"] isKindOfClass:[NSArray class]])
                            [layerInfo setValue:[[layerInfo objectForKey:@"grids"] objectAtIndex:0] forKey:@"gridURL"];
                        
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
                    
                    [updatedLayers addObject:layerInfo];
                }
                
                weakSelf.helpLabel.hidden      = NO;
                weakSelf.tileScrollView.hidden = NO;
                
                weakSelf.layers = [NSArray arrayWithArray:updatedLayers];
                
                // layout preview tiles
                //
                int pageCount = ([weakSelf.layers count] / 9) + ([weakSelf.layers count] % 9 ? 1 : 0);
                
                weakSelf.tileScrollView.contentSize = CGSizeMake((weakSelf.tileScrollView.frame.size.width * pageCount), weakSelf.tileScrollView.frame.size.height);
                
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
                            
                            // start downloads on first page
                            //
                            if (i == 0)
                                [tileView startDownload];

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
    
    [TestFlight passCheckpoint:@"browsed TileStream server"];
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
        
        NSDictionary *layerInfo = [self.layers objectAtIndex:tileView.tag];
        
        preview.info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [layerInfo objectForKey:@"tileURL"], @"tileURL",
                           ([layerInfo objectForKey:@"gridURL"] ? [layerInfo objectForKey:@"gridURL"] : @""), @"gridURL",
                           ([layerInfo objectForKey:@"template"] ? [layerInfo objectForKey:@"template"] : @""), @"template",
                           ([layerInfo objectForKey:@"formatter"] ? [layerInfo objectForKey:@"formatter"] : @""), @"formatter",
                           ([layerInfo objectForKey:@"legend"] ? [layerInfo objectForKey:@"legend"] : @""), @"legend",
                           ([layerInfo objectForKey:@"download"] ? [layerInfo objectForKey:@"download"] : @""), @"download",
                           ([layerInfo objectForKey:@"filesize"] ? [layerInfo objectForKey:@"filesize"] : @""), @"filesize",
                           [NSNumber numberWithInt:[[layerInfo objectForKey:@"minzoom"] intValue]], @"minzoom", 
                           [NSNumber numberWithInt:[[layerInfo objectForKey:@"maxzoom"] intValue]], @"maxzoom", 
                           [layerInfo objectForKey:@"id"], @"id", 
                           [layerInfo objectForKey:@"name"], @"name", 
                           [layerInfo objectForKey:@"center"], @"center",
                           [[layerInfo objectForKey:@"bounds"] componentsJoinedByString:@","], @"bounds",
                           nil];
        
        DSMapBoxStyledModalNavigationController *wrapper = [[DSMapBoxStyledModalNavigationController alloc] initWithRootViewController:preview];
        
        wrapper.navigationBar.translucent = YES;
        
        wrapper.modalPresentationStyle = UIModalPresentationFullScreen;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
        
        [self presentModalViewController:wrapper animated:YES];
    });
}

#pragma mark -

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    UIView *containerView = [scrollView.subviews objectAtIndex:(scrollView.contentOffset.x / scrollView.bounds.size.width)];
    
    for (DSMapBoxLayerAddTileView *tileView in containerView.subviews)
        [tileView startDownload];
}

@end