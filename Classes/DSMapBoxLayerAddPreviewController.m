    //
//  DSMapBoxLayerAddPreviewController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddPreviewController.h"

#import "DSMapView.h"
#import "RMTileStreamSource.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapContents.h"
#import "DSMapBoxTintedBarButtonItem.h"
#import "RMInteractiveSource.h"
#import "DSMapBoxDataOverlayManager.h"
#import "MapBoxConstants.h"

@implementation DSMapBoxLayerAddPreviewController

@synthesize info;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = [NSString stringWithFormat:@"Preview %@", [info objectForKey:@"name"]];
    
    self.navigationItem.rightBarButtonItem = [[[DSMapBoxTintedBarButtonItem alloc] initWithTitle:@"Done"
                                                                                          target:self
                                                                                          action:@selector(dismissPreview:)] autorelease];
    
    // map view
    //
    NSArray *centerParts = [info objectForKey:@"center"];
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[centerParts objectAtIndex:1] floatValue], [[centerParts objectAtIndex:0] floatValue]);
    
    RMTileStreamSource *source = [[[RMTileStreamSource alloc] initWithInfo:info] autorelease];
    
    [[[DSMapContents alloc] initWithView:mapView 
                              tilesource:source
                            centerLatLon:center
                               zoomLevel:([[centerParts objectAtIndex:2] floatValue] >= kLowerZoomBounds ? [[centerParts objectAtIndex:2] floatValue] : kLowerZoomBounds)
                            maxZoomLevel:[source maxZoom]
                            minZoomLevel:[source minZoom]
                         backgroundImage:nil] autorelease];
    
    mapView.enableRotate = NO;
    mapView.deceleration = NO;
    
    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loading.png"]];
    
    // setup interactivity manager
    //
    overlayManager = [[DSMapBoxDataOverlayManager alloc] initWithMapView:mapView];
    
    mapView.delegate = overlayManager;
    mapView.interactivityDelegate = overlayManager;
    
    // setup metadata label
    //
    NSMutableString *metadata = [NSMutableString string];

    if ([[info objectForKey:@"minzoom"] isEqual:[info objectForKey:@"maxzoom"]])
        [metadata appendString:[NSString stringWithFormat:@"  Zoom level %@", [info objectForKey:@"minzoom"]]];
    
    else
        [metadata appendString:[NSString stringWithFormat:@"  Zoom levels %@-%@", [info objectForKey:@"minzoom"], [info objectForKey:@"maxzoom"]]];
    
    if ( ! [((NSString *)[info objectForKey:@"type"]) isEqualToString:@"baselayer"])
        [metadata appendString:@", overlay"];
    
    if ([source supportsInteractivity])
        [metadata appendString:@", interactive"];

    if ([source coversFullWorld])
        [metadata appendString:@", full-world coverage"];
    
    metadataLabel.text = metadata;
    
    [TestFlight passCheckpoint:@"previewed TileStream layer"];
}

- (void)dealloc
{
    [overlayManager release];
    [info release];
    
    [super dealloc];
}

#pragma mark -

- (void)dismissPreview:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end