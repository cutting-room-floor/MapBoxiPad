//
//  MapBoxiPadDemoViewController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxiPadDemoViewController.h"

#import "DSMapBoxSQLiteTileSource.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxDataOverlayManager.h"
#import "DSMapContents.h"
#import "DSMapBoxLayerController.h"
#import "DSMapBoxLayerManager.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMMapView.h"
#import "RMTileSource.h"

#import "TouchXML.h"

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#define kStartingLat   42.0f
#define kStartingLon   55.0f
#define kStartingZoom   4.0f

#define kCenteringLat  33.919241123962202f
#define kCenteringLon  66.074245801675474f
#define kCenteringZoom  6.0f


@interface MapBoxiPadDemoViewController (MapBoxiPadDemoViewControllerPrivate)

void SoundCompletionProc (SystemSoundID sound, void *clientData);

@end

#pragma mark -

@implementation MapBoxiPadDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // starting setup info
    //
    CLLocationCoordinate2D startingPoint;
    
    startingPoint.latitude  = kStartingLat;
    startingPoint.longitude = kStartingLon;
    
    // base map view
    //
    DSMapBoxSQLiteTileSource *source = [[[DSMapBoxSQLiteTileSource alloc] init] autorelease];
    
	[[[DSMapContents alloc] initWithView:mapView 
                              tilesource:source
                            centerLatLon:startingPoint
                               zoomLevel:kStartingZoom
                            maxZoomLevel:[source maxZoom]
                            minZoomLevel:[source minZoom]
                         backgroundImage:nil] autorelease];
    
    mapView.enableRotate = NO;
    mapView.deceleration = YES;

    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.jpg"]];
    
    // data overlay & layer managers
    //
    dataOverlayManager = [[DSMapBoxDataOverlayManager alloc] initWithMapView:mapView];
    dataOverlayManager.mapView = mapView;
    mapView.delegate = dataOverlayManager;
    layerManager = [[DSMapBoxLayerManager alloc] initWithDataOverlayManager:dataOverlayManager overBaseMapView:mapView];
    
    // watch for tile changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileSetDidChange:)
                                                 name:DSMapBoxTileSetChangedNotification
                                               object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxTileSetChangedNotification object:nil];
    
    [layersPopover release];
    [layerManager release];
    [dataOverlayManager release];

    [super dealloc];
}

#pragma mark -

- (IBAction)tappedRecenterButton:(id)sender
{
    CLLocationCoordinate2D center;
    
    center.latitude  = kCenteringLat;
    center.longitude = kCenteringLon;
    
    [mapView moveToLatLong:center];
    
    mapView.contents.zoom = kCenteringZoom;

    [mapView setRotation:0.0];
    
    [mapView setNeedsDisplay];
}

- (void)openKMLFile:(NSURL *)fileURL
{
    NSError *error = nil;
    
    SimpleKML *newKML = [SimpleKML KMLWithContentsofURL:fileURL error:&error];

    if (error)
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to parse KML file"
                                                         message:[NSString stringWithFormat:@"Unable to parse the given KML file. The parser reported: %@", error] 
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil] autorelease];
        
        [alert show];
    }
    else if (newKML)
    {
        NSString *source      = [fileURL relativePath];
        NSString *filename    = [[fileURL relativePath] lastPathComponent];
        NSString *destination = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], filename];
        
        [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:NULL];
        
        [self tappedLayersButton:self];
    }
}

- (IBAction)tappedLayersButton:(id)sender
{
    if (layersPopover.popoverVisible)
        [layersPopover dismissPopoverAnimated:YES];
    
    else
    {
        if ( ! layersPopover)
        {
            DSMapBoxLayerController *layerController = [[[DSMapBoxLayerController alloc] initWithNibName:nil bundle:nil] autorelease];
            
            layerController.layerManager = layerManager;
            
            UINavigationController *wrapper = [[[UINavigationController alloc] initWithRootViewController:layerController] autorelease];
            
            layerController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Library" 
                                                                                                 style:UIBarButtonItemStylePlain 
                                                                                                target:self
                                                                                                action:@selector(tappedLibraryButton:)] autorelease];
            
            layersPopover = [[UIPopoverController alloc] initWithContentViewController:wrapper];
            
            layersPopover.passthroughViews = nil;
        }
        
        [layersPopover presentPopoverFromBarButtonItem:layersButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)tappedLibraryButton:(id)sender
{
    NSLog(@"show library");
}

- (void)tileSetDidChange:(NSNotification *)notification
{
    // hide layers popover
    //
    [layersPopover dismissPopoverAnimated:NO];
    
    // get an image of the current map
    //
    UIGraphicsBeginImageContext(mapView.bounds.size);
    [mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // swap map view with image view
    //
    UIImageView *snapshotView = [[[UIImageView alloc] initWithFrame:mapView.frame] autorelease];
    snapshotView.image = snapshot;
    [self.view insertSubview:snapshotView atIndex:0];
    [mapView removeFromSuperview];
    
    // adjust map view to new auto-reloaded tile source settings
    //
    DSMapBoxSQLiteTileSource *tileSource = mapView.contents.tileSource;
    
    float newZoom = -1;
    
    if (mapView.contents.zoom < [tileSource minZoom])
        newZoom = [tileSource minZoom];
    
    else if (mapView.contents.zoom > [tileSource maxZoom])
        newZoom = [tileSource maxZoom];
    
    if (newZoom >= 0)
        mapView.contents.zoom = newZoom;

    mapView.contents.minZoom = [tileSource minZoom];
    mapView.contents.maxZoom = [tileSource maxZoom];

    // jiggle the map a bit to reload
    //
    float currentZoom = mapView.contents.zoom;
    
    if (currentZoom < [tileSource maxZoom])
        mapView.contents.zoom = currentZoom + 1.0;
    
    else if (currentZoom > [tileSource minZoom])
        mapView.contents.zoom = currentZoom - 1.0;

    mapView.contents.zoom = currentZoom;
    
    // start up page turn sound effect
    //
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"page_flip" ofType:@"wav"]];
    SystemSoundID sound;
    AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &sound);
    AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, SoundCompletionProc, self);
    AudioServicesPlaySystemSound(sound);
    
    // animate swap from old snapshot to new map
    //
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
    [UIView setAnimationDuration:0.8];
    [snapshotView removeFromSuperview];
    [self.view insertSubview:mapView atIndex:0];
    [UIView commitAnimations];
}

void SoundCompletionProc (SystemSoundID sound, void *clientData)
{
    AudioServicesDisposeSystemSoundID(sound);
}

@end