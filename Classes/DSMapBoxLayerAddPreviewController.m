    //
//  DSMapBoxLayerAddPreviewController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddPreviewController.h"

#import "DSMapView.h"
#import "RMTileStreamSource.h"
#import "DSMapContents.h"
#import "RMInteractiveSource.h"
#import "DSMapBoxDataOverlayManager.h"

@interface DSMapBoxLayerAddPreviewController ()

@property (nonatomic, strong) DSMapBoxDataOverlayManager *overlayManager;

@end

#pragma mark -

@implementation DSMapBoxLayerAddPreviewController

@synthesize mapView;
@synthesize metadataLabel;
@synthesize info;
@synthesize overlayManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = [NSString stringWithFormat:@"Preview %@", [info objectForKey:@"name"]];
    
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(dismissPreview:)
                                                                          tintColor:kMapBoxBlue];
    
    // map view
    //
    NSArray *centerParts = [info objectForKey:@"center"];
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[centerParts objectAtIndex:1] floatValue], [[centerParts objectAtIndex:0] floatValue]);
    
    RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithInfo:self.info];
    
    [[DSMapContents alloc] initWithView:self.mapView 
                             tilesource:source
                           centerLatLon:center
                              zoomLevel:([[centerParts objectAtIndex:2] floatValue] >= kLowerZoomBounds ? [[centerParts objectAtIndex:2] floatValue] : kLowerZoomBounds)
                           maxZoomLevel:[source maxZoom]
                           minZoomLevel:[source minZoom]
                        backgroundImage:nil
                            screenScale:0.0];
    
    self.mapView.enableRotate = NO;
    self.mapView.deceleration = NO;
    
    self.mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loading.png"]];
    
    // setup interactivity manager
    //
    self.overlayManager = [[DSMapBoxDataOverlayManager alloc] initWithMapView:self.mapView];
    
    self.mapView.delegate = self.overlayManager;
    self.mapView.interactivityDelegate = self.overlayManager;
    
    // setup metadata label
    //
    NSMutableString *metadata = [NSMutableString string];

    if ([[self.info objectForKey:@"minzoom"] isEqual:[self.info objectForKey:@"maxzoom"]])
        [metadata appendString:[NSString stringWithFormat:@"  Zoom level %@", [self.info objectForKey:@"minzoom"]]];
    
    else
        [metadata appendString:[NSString stringWithFormat:@"  Zoom levels %@-%@", [self.info objectForKey:@"minzoom"], [self.info objectForKey:@"maxzoom"]]];
    
    if ([source supportsInteractivity])
        [metadata appendString:@", interactive"];
    
    if ([[source legend] length])
        [metadata appendString:@", legend"];

    if ([source coversFullWorld])
        [metadata appendString:@", full-world coverage"];
    
    if ([[self.info objectForKey:@"download"] length] && [[self.info objectForKey:@"filesize"] isKindOfClass:[NSNumber class]])
        [metadata appendString:[NSString stringWithFormat:@", available offline (%qu MB)", ([[self.info objectForKey:@"filesize"] longLongValue] / (1024 * 1024))]];
    
    self.metadataLabel.text = metadata;
    
    [TestFlight passCheckpoint:@"previewed TileStream layer"];
}

#pragma mark -

- (void)dismissPreview:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end