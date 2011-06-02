    //
//  DSMapBoxLayerAddTileStreamBrowseController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "CJSONDeserializer.h"
#import <CoreLocation/CoreLocation.h>
#import "RMTile.h"
#import "DSMapBoxLayerAddPreviewController.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxLayerAddTileStreamBrowseController

@synthesize serverURL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    tileCarousel.type = iCarouselTypeCoverFlow;
    tileCarousel.hidden = YES;
    
    nameLabel.text = @"";
    detailsLabel.text = @"";
    helpLabel.hidden = YES;
    
    [spinner startAnimating];
    
    items = [[NSArray array] retain];
    
    selectedLayers = [[NSMutableArray array] retain];
    
    imagesToDownload = [[NSMutableArray array] retain];
    
    self.navigationItem.title = @"Browse Server";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Layer"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(tappedDoneButton:)] autorelease];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSString *fullURLString = [NSString stringWithFormat:@"%@/api/v1/Map", self.serverURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)dealloc
{
    // needed to avoid follow-up delegate messaging
    //
    [tileCarousel removeFromSuperview];
    tileCarousel.delegate = nil;
    
    [items release];
    [imagesToDownload release];
    [selectedLayers release];

    [serverURL release];
    
    [super dealloc];
}


#pragma mark -

- (void)checkForImageDownloads
{
    if (activeDownloadIndex <= [items count])
    {
        NSURL *nextURL = [imagesToDownload objectAtIndex:activeDownloadIndex - 1];
        
        downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:nextURL] delegate:self];
    }
}

- (void)tappedDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DSMapBoxLayersAdded" 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:selectedLayers forKey:@"selectedLayers"]];
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        // preview tiles in a map view
        //
        DSMapBoxLayerAddPreviewController *preview = [[[DSMapBoxLayerAddPreviewController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        NSDictionary *layer = [[[items objectAtIndex:gestureRecognizer.view.tag - 1 - 100] objectForKey:@"layers"] lastObject];
        
        NSString *baseHostname;
        
        if ([[self.serverURL absoluteString] isEqualToString:@"http://tiles.mapbox.com/mapbox"])
            baseHostname = @"http://a.tiles.mapbox.com:80/mapbox";
        
        else
            baseHostname = [self.serverURL absoluteString];
        
        preview.info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [[NSURL URLWithString:baseHostname] host], @"tileHostname", 
                           [[NSURL URLWithString:baseHostname] port], @"tilePort", 
                           ([[NSURL URLWithString:baseHostname] path] ? [[NSURL URLWithString:baseHostname] path] : @""), @"tilePath", 
                           [NSNumber numberWithInt:[[layer objectForKey:@"minzoom"] intValue]], @"minzoom", 
                           [NSNumber numberWithInt:[[layer objectForKey:@"maxzoom"] intValue]], @"maxzoom", 
                           [layer objectForKey:@"id"], @"id", 
                           [layer objectForKey:@"version"], @"version", 
                           [layer objectForKey:@"name"], @"name", 
                           [layer objectForKey:@"description"], @"description", 
                           [layer objectForKey:@"center"], @"center",
                           nil];
        
        UINavigationController *wrapper = [[[UINavigationController alloc] initWithRootViewController:preview] autorelease];
        
        wrapper.modalPresentationStyle = UIModalPresentationFormSheet;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
        
        preview.navigationItem.title = [layer objectForKey:@"name"];
        preview.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                                   target:self
                                                                                                   action:@selector(dismissPreview:)] autorelease];
        
        [self presentModalViewController:wrapper animated:YES];
    }
    else if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        // wiggle tile & mark it selected
        //
        NSDictionary *layer = [items objectAtIndex:(gestureRecognizer.view.tag - 1 - 100)];
        
        // update selection
        //
        if ([selectedLayers containsObject:layer])
            [selectedLayers removeObject:layer];
        
        else
            [selectedLayers addObject:layer];
        
        // enable/disable action button
        //
        if ([selectedLayers count])
            self.navigationItem.rightBarButtonItem.enabled = YES;
        
        else
            self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // modify action button title
        //
        if ([selectedLayers count] > 1)
            self.navigationItem.rightBarButtonItem.title = @"Add Layers";
        
        else
            self.navigationItem.rightBarButtonItem.title = @"Add Layer";
        
        // toggle the checkmark
        //
        [UIView beginAnimations:nil context:nil];
        
        [UIView setAnimationDuration:2.0];
        
        UIView *tileView  = [gestureRecognizer.view viewWithTag:gestureRecognizer.view.tag - 100];
        UIView *checkView = [tileView viewWithTag:tileView.tag + 200];
        
        checkView.hidden = ! checkView.hidden;
        
        [UIView commitAnimations];
        
        // wiggle-rotate the tile
        //
        [UIView beginAnimations:nil context:tileView.superview];
        
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:self];
        
        tileView.superview.transform = CGAffineTransformMakeRotation((2 * M_PI) / 24);
        
        [UIView commitAnimations];
    }
}

- (void)dismissPreview:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    [connection autorelease];
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
    [connection autorelease];
    
    UIImage *image = [UIImage imageWithData:receivedData];
    
    if (image)
    {
        ((UIImageView *)[tileCarousel viewWithTag:activeDownloadIndex]).image = image;

        activeDownloadIndex++;
        
        [self checkForImageDownloads];
    }
    else
    {
        [spinner stopAnimating];
        
        NSError *error = nil;
        
        [items release];
        
        items = [[[CJSONDeserializer deserializer] deserializeAsArray:receivedData error:&error] retain];
        
        if (error)
            NSLog(@"%@", error);
        
        else
        {
            for (int i = 0; i < [items count]; i++)
            {
                NSDictionary *layer = [[[items objectAtIndex:i] objectForKey:@"layers"] objectAtIndex:0];
                
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
                
                NSString *baseHostname;
                
                if ([[self.serverURL absoluteString] isEqualToString:@"http://tiles.mapbox.com/mapbox"])
                    baseHostname = @"http://a.tiles.mapbox.com/mapbox";

                else
                    baseHostname = [self.serverURL absoluteString];
                
                NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1.0.0/%@/%d/%d/%d.png", 
                                                        baseHostname, [layer objectForKey:@"id"], tile.zoom, tile.x, tile.y]];
                
                [imagesToDownload addObject:imageURL];
            }
            
            activeDownloadIndex = 1;
            
            [self checkForImageDownloads];
            
            [tileCarousel reloadData];
            
            [self carouselCurrentItemIndexUpdated:tileCarousel];
            
            tileCarousel.hidden = NO;

            helpLabel.hidden = NO;
        }
    }
}

#pragma mark -

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index
{
    // create tile view
    //
    UIView *baseView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 256, 256)] autorelease];
    
    baseView.backgroundColor = [UIColor whiteColor];
    
    baseView.layer.shadowOpacity = 0.5;
    baseView.layer.shadowOffset = CGSizeMake(0, -1);
    baseView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:baseView.bounds] CGPath];

    baseView.tag = index + 1 + 100;
    
    // add image subview
    //
    UIImageView *view = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder.png"]] autorelease];
    
    view.tag = index + 1;
    
    [baseView addSubview:view];

    // setup gestures on base view
    //
    UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
    
    UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];
    
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    
    baseView.gestureRecognizers = [NSArray arrayWithObjects:pinch, tap, nil];
    
    // add selection checkmark
    //
    UIImageView *check = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check.png"]] autorelease];
    
    [view addSubview:check];
    
    check.frame = CGRectMake(view.frame.size.width - check.frame.size.width + 10, -10, check.frame.size.width, check.frame.size.height);
    
    check.layer.shadowOpacity = 0.5;
    check.layer.shadowOffset = CGSizeMake(0, -1);
    
    check.hidden = YES;
    
    check.tag = index + 1 + 200;
    
    return baseView;
}

#pragma mark -

- (float)carouselItemWidth:(iCarousel *)carousel
{
    return 270;
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel
{
    return NO;
}

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel
{
    nameLabel.text = [[[[items objectAtIndex:carousel.currentItemIndex] objectForKey:@"layers"] lastObject] objectForKey:@"name"];
    
    NSString *details = [NSString stringWithFormat:@"Zoom Levels %@-%@", 
                            [[[[items objectAtIndex:carousel.currentItemIndex] objectForKey:@"layers"] lastObject] objectForKey:@"minzoom"], 
                            [[[[items objectAtIndex:carousel.currentItemIndex] objectForKey:@"layers"] lastObject] objectForKey:@"maxzoom"]];
    
    detailsLabel.text = details;
}

#pragma mark -

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    // tile rotation back to start
    //
    UIView *view = (UIView *)context;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.1];
    
    view.transform = CGAffineTransformRotate(view.transform, (-2 * M_PI) / 24);
    
    [UIView commitAnimations];
}

@end