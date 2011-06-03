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

#import "CJSONDeserializer.h"

#import "RMTile.h"

#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

NSString *const DSMapBoxLayersAdded = @"DSMapBoxLayersAdded";

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
    
    layers = [[NSArray array] retain];
    
    selectedLayers = [[NSMutableArray array] retain];
    selectedImages = [[NSMutableArray array] retain];
    
    imagesToDownload = [[NSMutableArray array] retain];
    
    self.navigationItem.title = @"Browse Server";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Layer"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(tappedDoneButton:)] autorelease];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@", self.serverURL, kTileStreamAPIPath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)dealloc
{
    // needed to avoid follow-up delegate messaging
    //
    [tileCarousel removeFromSuperview];
    tileCarousel.delegate = nil;
    
    [layers release];
    [imagesToDownload release];
    [selectedLayers release];
    [selectedImages release];

    [serverURL release];
    
    [super dealloc];
}


#pragma mark -

- (void)checkForImageDownloads
{
    if (activeDownloadIndex <= [layers count])
    {
        NSURL *nextURL = [imagesToDownload objectAtIndex:activeDownloadIndex - 1];
        
        downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:nextURL] delegate:self];
    }
}

- (void)tappedDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxLayersAdded 
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:selectedLayers, @"selectedLayers",
                                                                                                          selectedImages, @"selectedImages", 
                                                                                                          nil]];
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        // preview tiles in a map view
        //
        DSMapBoxLayerAddPreviewController *preview = [[[DSMapBoxLayerAddPreviewController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        NSDictionary *layer = [layers objectAtIndex:gestureRecognizer.view.tag - 1 - 100];
        
        NSURL *tileURL;
        
        if ([[self.serverURL absoluteString] hasPrefix:kTileStreamHostedBaseURL])
            tileURL = [NSURL URLWithString:[kTileStreamHostedTileURL stringByAppendingString:[self.serverURL path]]];
        
        else
            tileURL = self.serverURL;
        
        preview.info = [NSDictionary dictionaryWithObjectsAndKeys:
                           [tileURL scheme], @"tileScheme",
                           [tileURL host], @"tileHostname", 
                           ([tileURL port] ? [tileURL port] : [NSNumber numberWithInt:80]), @"tilePort", 
                           ([tileURL path] ? [tileURL path] : @""), @"tilePath", 
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
        // bounce tile & mark it selected
        //
        NSDictionary *layer = [layers objectAtIndex:(gestureRecognizer.view.tag - 1 - 100)];
        UIImage *layerImage = ((UIImageView *)[gestureRecognizer.view viewWithTag:gestureRecognizer.view.tag - 100]).image;
        
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
        
        // bounce-resize the tile
        //
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void)
                         { 
                             tileView.superview.transform = CGAffineTransformMakeScale(0.9, 0.9);
                         } 
                         completion:^(BOOL finished)
                         { 
                             [UIView beginAnimations:nil context:nil];

                             [UIView setAnimationDuration:0.1];
                             [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                             
                             tileView.superview.transform = CGAffineTransformScale(tileView.superview.transform, 1 / 0.9, 1 / 0.9);

                             [UIView commitAnimations];
                         }];
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
        
        NSMutableArray *newLayers = [NSMutableArray arrayWithArray:[[CJSONDeserializer deserializer] deserializeAsArray:receivedData error:&error]];
        
        if (error)
            NSLog(@"%@", error);
        
        else
        {
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
                
                NSURL *tileURL;
                
                if ([[self.serverURL absoluteString] hasPrefix:kTileStreamHostedBaseURL])
                    tileURL = [NSURL URLWithString:[kTileStreamHostedTileURL stringByAppendingString:[self.serverURL path]]];
                
                else
                    tileURL = self.serverURL;
                
                NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1.0.0/%@/%d/%d/%d.png", 
                                                           tileURL, [layer objectForKey:@"id"], tile.zoom, tile.x, tile.y]];
                
                [imagesToDownload addObject:imageURL];
                
                // update layer for server-wide variables
                //
                [layer setValue:[self.serverURL scheme]                                                       forKey:@"apiScheme"];
                [layer setValue:[self.serverURL host]                                                         forKey:@"apiHostname"];
                [layer setValue:([self.serverURL port] ? [self.serverURL port] : [NSNumber numberWithInt:80]) forKey:@"apiPort"];
                [layer setValue:([self.serverURL path] ? [self.serverURL path] : @"")                         forKey:@"apiPath"];
                
                if ([layer objectForKey:@"host"] && [[layer objectForKey:@"host"] isKindOfClass:[NSArray class]])
                {
                    NSURL *tileHostURL = [NSURL URLWithString:[[layer objectForKey:@"host"] objectAtIndex:0]];
                    
                    [layer setValue:[tileHostURL scheme]                                                    forKey:@"tileScheme"];
                    [layer setValue:[tileHostURL host]                                                      forKey:@"tileHostname"];
                    [layer setValue:([tileHostURL port] ? [tileHostURL port] : [NSNumber numberWithInt:80]) forKey:@"tilePort"];
                    [layer setValue:([tileHostURL path] ? [tileHostURL path] : @"")                         forKey:@"tilePath"];
                }
                else
                {
                    [layer setValue:[tileURL scheme]                                                forKey:@"tileScheme"];
                    [layer setValue:[tileURL host]                                                  forKey:@"tileHostname"];
                    [layer setValue:([tileURL port] ? [tileURL port] : [NSNumber numberWithInt:80]) forKey:@"tilePort"];
                    [layer setValue:([tileURL path] ? [tileURL path] : @"")                         forKey:@"tilePath"];
                }
                
                [newLayers replaceObjectAtIndex:i withObject:layer];
            }
            
            [layers release];
            
            layers = [[NSArray arrayWithArray:newLayers] retain];
            
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
    return [layers count];
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
    nameLabel.text = [[layers objectAtIndex:carousel.currentItemIndex] objectForKey:@"name"];
    
    NSString *details = [NSString stringWithFormat:@"Zoom Levels %@-%@", 
                            [[layers objectAtIndex:carousel.currentItemIndex] objectForKey:@"minzoom"], 
                            [[layers objectAtIndex:carousel.currentItemIndex] objectForKey:@"maxzoom"]];
    
    detailsLabel.text = details;
}

@end