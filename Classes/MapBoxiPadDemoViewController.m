//
//  MapBoxiPadDemoViewController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxiPadDemoViewController.h"
#import "DSMapBoxSQLiteTileSource.h"
#import "RMMapContents.h"
#import "TouchXML.h"
#import "RMMarker.h"
#import "RMMarkerManager.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxTileSetChooserController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SimpleKML.h"
#import "SimpleKMLFeature.h"
#import "SimpleKMLContainer.h"
#import "SimpleKMLPlacemark.h"
#import "SimpleKMLPoint.h"
#import "SimpleKMLStyle.h"
#import "SimpleKMLIconStyle.h"
#import "SimpleKML_UIImage.h"

#define kStartingLat     19.5f
#define kStartingLon    -74.0f
#define kStartingZoom     8.0f
#define kPlacemarkAlpha   0.7f

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
                            minZoomLevel:kStartingZoom - 1.0f
                         backgroundImage:nil] autorelease];

    mapView.enableRotate = NO;
    mapView.deceleration = YES;

    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"404803.jpg"]];
    
    mapView.delegate = self;
    
    clickLabel.text = @"";
    clickStripe.hidden = YES;
    
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
    
    [timer release];

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

- (IBAction)tappedKMLButton:(id)sender
{
    if ([[mapView.contents.markerManager markers] count])
    {
        [kmlButton setTitle:@"Turn KML On"];

        [mapView.contents.markerManager removeMarkers];
        
        clickStripe.hidden = YES;
        clickLabel.text = @"";

        return;
    }
    
    [kmlButton setTitle:@"Turn KML Off"];
    
    SimpleKML *kml = [SimpleKML KMLWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"haiti_commune_term" ofType:@"kml"] error:NULL];
    
    CGFloat zoom = mapView.contents.zoom;
    CGFloat power;
    
    while (zoom > 1)
    {
        zoom = zoom / 2;
        power++;
    }
    
    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        for (SimpleKMLFeature *feature in ((SimpleKMLContainer *)kml.feature).features)
        {
            if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && 
                ((SimpleKMLPlacemark *)feature).sharedStyle        && 
                ((SimpleKMLPlacemark *)feature).sharedStyle.iconStyle)
            {
                UIImage *icon = ((SimpleKMLPlacemark *)feature).sharedStyle.iconStyle.icon;
                
                RMMarker *marker = [[[RMMarker alloc] initWithUIImage:[icon imageWithAlphaComponent:kPlacemarkAlpha]] autorelease];
                
                // we store the original icon & alpha value for later use in the pulse animation
                //
                marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                                     @"marker", 
                                                                         feature.name,                               @"label", 
                                                                         icon,                                       @"icon",
                                                                         [NSNumber numberWithFloat:kPlacemarkAlpha], @"alpha",
                                                                         nil];
                
                [[[RMMarkerManager alloc] initWithContents:mapView.contents] autorelease];
                
                [mapView.contents.markerManager addMarker:marker AtLatLong:((SimpleKMLPlacemark *)feature).point.coordinate];
            }
        }
    }
}

- (IBAction)tappedTilesButton:(id)sender
{
    [popover dismissPopoverAnimated:YES];
    [popover release];
    popover = nil;
    
    DSMapBoxTileSetChooserController *chooser = [[[DSMapBoxTileSetChooserController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    popover = [[UIPopoverController alloc] initWithContentViewController:chooser];
    
    [popover presentPopoverFromBarButtonItem:tilesButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    popover.passthroughViews = nil;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    clickStripe.hidden = NO;
    
    clickLabel.text = [lastMarkerInfo objectForKey:@"label"];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

    CGPoint oldCenter = clickLabel.center;
    clickLabel.center  = CGPointMake(oldCenter.x + 200, oldCenter.y);
    
    oldCenter = clickStripe.center;
    clickStripe.center = CGPointMake(oldCenter.x + 200, oldCenter.y);
    
    [UIView commitAnimations];
}

- (void)pulse:(NSTimer *)aTimer
{
    // we go after the stored marker metadata since you can't get the original sized image nor the alpha from an RMMarker
    //
    RMMarker *marker = [lastMarkerInfo  objectForKey:@"marker"];
    UIImage  *image  = [lastMarkerInfo  objectForKey:@"icon"];
    CGFloat   alpha  = [[lastMarkerInfo objectForKey:@"alpha"] floatValue];
    
    if (alpha >= kPlacemarkAlpha)
        alpha = 0.1;

    else
        alpha = alpha + 0.1;

    [marker replaceUIImage:[image imageWithAlphaComponent:alpha]];

    [lastMarkerInfo setObject:[NSNumber numberWithFloat:alpha] forKey:@"alpha"];
}

- (void)tileSetDidChange:(NSNotification *)notification
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        [popover release];
        popover = nil;
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

- (void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    // don't respond to clicks on currently highlighted marker
    //
    if ([clickLabel.text isEqualToString:[((NSDictionary *)marker.data) objectForKey:@"label"]])
        return;
    
    // return last marker to full alpha
    //
    if (lastMarkerInfo)
    {
        [timer invalidate];
        [timer release];

        RMMarker *lastMarker      = [lastMarkerInfo objectForKey:@"marker"];
        UIImage  *lastMarkerImage = [lastMarkerInfo objectForKey:@"icon"];
        
        [lastMarker replaceUIImage:[lastMarkerImage imageWithAlphaComponent:kPlacemarkAlpha]];
    }
    
    // animate label swap
    //
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    if ([clickLabel.text isEqualToString:@""])
        [UIView setAnimationDuration:0.0];
    
    CGPoint oldCenter  = clickLabel.center;
    clickLabel.center  = CGPointMake(oldCenter.x - 200, oldCenter.y);
    
            oldCenter  = clickStripe.center;
    clickStripe.center = CGPointMake(oldCenter.x - 200, oldCenter.y);
    
    [UIView commitAnimations];
    
    // update last marker & fire off pulse animation on this one
    //
    [lastMarkerInfo release];
    lastMarkerInfo = [[NSMutableDictionary dictionaryWithDictionary:((NSDictionary *)marker.data)] retain];
    
    timer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(pulse:)
                                            userInfo:nil
                                             repeats:YES] retain];
}

@end