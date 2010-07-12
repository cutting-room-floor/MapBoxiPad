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
#import "DSMapBoxTileSetChooserController.h"
#import "DSMapBoxOverlayManager.h"

#import "SimpleKML.h"
#import "SimpleKML_UIImage.h"
#import "SimpleKMLPlacemark.h"
#import "SimpleKMLPoint.h"

#import "RMMapContents.h"
#import "RMMarker.h"

#import "TouchXML.h"

#import <AudioToolbox/AudioToolbox.h>

#define kStartingLat    51.4791f
#define kStartingLon     0.9f
#define kStartingZoom    3.0f

@interface MapBoxiPadDemoViewController (MapBoxiPadDemoViewControllerPrivate)

void SoundCompletionProc (SystemSoundID sound, void *clientData);
- (void)updateTilesButtonTitle;

@end

#pragma mark -

@implementation MapBoxiPadDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood-walnut-background-tile.jpg"]];
    
    CLLocationCoordinate2D startingPoint;
    
	startingPoint.latitude  = kStartingLat;
	startingPoint.longitude = kStartingLon;
    
    DSMapBoxSQLiteTileSource *source = [[[DSMapBoxSQLiteTileSource alloc] init] autorelease];
    
	[[[RMMapContents alloc] initWithView:mapView 
                              tilesource:source
                            centerLatLon:startingPoint
                               zoomLevel:kStartingZoom
                            maxZoomLevel:[source maxZoom]
                            minZoomLevel:[source minZoom]
                         backgroundImage:nil] autorelease];

    overlayManager = [[DSMapBoxOverlayManager alloc] initWithMapView:mapView];

    mapView.enableRotate = NO;
    mapView.deceleration = YES;

    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"404803.jpg"]];
    
    mapView.delegate = overlayManager;
    
    [self updateTilesButtonTitle];
    
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
    
    [overlayManager release];
    [kml release];

    [super dealloc];
}

#pragma mark -

- (IBAction)tappedAllowRotationButton:(id)sender
{
    mapView.enableRotate = ! mapView.enableRotate;
    
    [rotationButton setTitle:(mapView.enableRotate ? @"Disallow Rotation" : @"Allow Rotation")];
    
    mapView.rotation = 0.0f;
    
    [mapView setNeedsDisplay];
}

- (IBAction)tappedRecenterButton:(id)sender
{
    CLLocationCoordinate2D center;
    
    center.latitude  =  18.835861f;
    center.longitude = -73.296875f;
    
    [mapView moveToLatLong:center];
    
    mapView.contents.zoom = kStartingZoom;

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
        kml = [newKML retain];
        [self tappedKMLButton:self];
    }
}

- (IBAction)tappedKMLButton:(id)sender
{
    if ([[overlayManager overlays] count])
    {
        [kmlButton setTitle:@"Turn KML On"];

        [overlayManager removeAllOverlays];

        return;
    }
    
    [kmlButton setTitle:@"Turn KML Off"];
    
    if ( ! kml)
        kml = [[SimpleKML KMLWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"haiti_commune_term" ofType:@"kml"] error:NULL] retain];
    
    RMSphericalTrapezium overlayBounds = [overlayManager addOverlayForKML:kml];
    
    //[mapView.contents zoomWithLatLngBoundsNorthEast:overlayBounds.northeast SouthWest:overlayBounds.southwest];
}

- (IBAction)tappedGeoRSSButton:(id)sender
{
    DSMapBoxGeoRSSBrowserController *browser = [[[DSMapBoxGeoRSSBrowserController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    browser.modalPresentationStyle = UIModalPresentationPageSheet;
    browser.delegate = self;
    
    [self presentModalViewController:browser animated:YES];
}

- (IBAction)tappedTilesButton:(id)sender
{
    [tilesPopover dismissPopoverAnimated:YES];
    [tilesPopover release];
    tilesPopover = nil;
    
    DSMapBoxTileSetChooserController *chooser = [[[DSMapBoxTileSetChooserController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    tilesPopover = [[UIPopoverController alloc] initWithContentViewController:chooser];
    
    [tilesPopover presentPopoverFromBarButtonItem:tilesButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    tilesPopover.passthroughViews = nil;
}

- (void)tileSetDidChange:(NSNotification *)notification
{
    if (tilesPopover)
    {
        [tilesPopover dismissPopoverAnimated:NO];
        [tilesPopover release];
        tilesPopover = nil;
    }

    [self updateTilesButtonTitle];
    
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
    [self.view insertSubview:snapshotView belowSubview:toolbar];
    [mapView removeFromSuperview];
    
    // adjust map view to new settings
    //
    DSMapBoxSQLiteTileSource *newSource = [[[DSMapBoxSQLiteTileSource alloc] init] autorelease];
    
    float newZoom = -1;
    
    if (mapView.contents.zoom < [newSource minZoom])
        newZoom = [newSource minZoom];
    
    else if (mapView.contents.zoom > [newSource maxZoom])
        newZoom = [newSource maxZoom];
    
    if (newZoom >= 0)
        mapView.contents.zoom = newZoom;
    
    [mapView.contents removeAllCachedImages];
    
    mapView.contents.minZoom = [newSource minZoom];
    mapView.contents.maxZoom = [newSource maxZoom];
    
    mapView.contents.tileSource = newSource;

    // start up page turn sound effect
    //
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"page-flip-8" ofType:@"wav"]];
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
    [self.view insertSubview:mapView belowSubview:toolbar];
    [UIView commitAnimations];
}

void SoundCompletionProc (SystemSoundID sound, void *clientData)
{
    AudioServicesDisposeSystemSoundID(sound);
}

- (void)updateTilesButtonTitle
{
    tilesButton.title = [NSString stringWithFormat:@"Tiles: %@", [[DSMapBoxTileSetManager defaultManager] activeTileSetName]];
}

#pragma mark -

- (void)browserController:(DSMapBoxGeoRSSBrowserController *)controller didVisitFeedURL:(NSURL *)feedURL
{
    NSError *error = nil;
    
    NSString *rss = [NSString stringWithContentsOfURL:feedURL encoding:NSUTF8StringEncoding error:&error];
    
    RMSphericalTrapezium overlayBounds = [overlayManager addOverlayForGeoRSS:rss];
    
    //[mapView.contents zoomWithLatLngBoundsNorthEast:overlayBounds.northeast SouthWest:overlayBounds.southwest];
}

@end