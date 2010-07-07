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
#import "SimpleKMLLineString.h"
#import "SimpleKMLPolygon.h"
#import "SimpleKMLLinearRing.h"
#import "SimpleKMLLineStyle.h"
#import "SimpleKMLPolyStyle.h"
#import "RMPath.h"
#import "DSMapBoxBalloonController.h"

#define kStartingLat    51.4791f
#define kStartingLon     0.9f
#define kStartingZoom    3.0f
#define kPlacemarkAlpha  0.7f

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
    if ([[mapView.contents.markerManager markers] count])
    {
        [kmlButton setTitle:@"Turn KML On"];

        [mapView.contents.markerManager removeMarkers];
        
        clickStripe.hidden = YES;
        clickLabel.text = @"";

        return;
    }
    
    [kmlButton setTitle:@"Turn KML Off"];
    
    if ( ! kml)
        kml = [[SimpleKML KMLWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"haiti_commune_term" ofType:@"kml"] error:NULL] retain];
    
    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        for (SimpleKMLFeature *feature in ((SimpleKMLContainer *)kml.feature).features)
        {
            if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && 
                ((SimpleKMLPlacemark *)feature).point              &&
                ((SimpleKMLPlacemark *)feature).style              && 
                ((SimpleKMLPlacemark *)feature).style.iconStyle)
            {
                UIImage *icon = ((SimpleKMLPlacemark *)feature).style.iconStyle.icon;
                
                RMMarker *marker = [[[RMMarker alloc] initWithUIImage:icon] autorelease];
                
                if (((SimpleKMLPlacemark *)feature).style.balloonStyle)
                {
                    // we setup a balloon for later
                    //
                    marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                        @"marker",
                                                                             feature,                       @"placemark",
                                                                             [NSNumber numberWithBool:YES], @"hasBalloon",
                                                                             nil];
                }
                else
                {
                    // we store the original icon & alpha value for later use in the pulse animation
                    //
                    marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                                     @"marker", 
                                                                             feature.name,                               @"label", 
                                                                             icon,                                       @"icon",
                                                                             [NSNumber numberWithFloat:kPlacemarkAlpha], @"alpha",
                                                                             nil];
                }
                
                [[[RMMarkerManager alloc] initWithContents:mapView.contents] autorelease];
                
                [mapView.contents.markerManager addMarker:marker AtLatLong:((SimpleKMLPlacemark *)feature).point.coordinate];
            }
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).lineString         &&
                     ((SimpleKMLPlacemark *)feature).style              && 
                     ((SimpleKMLPlacemark *)feature).style.lineStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:mapView.contents] autorelease];
                
                path.lineColor = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;
                path.lineWidth = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                path.fillColor = [UIColor clearColor];
                
                SimpleKMLLineString *lineString = ((SimpleKMLPlacemark *)feature).lineString;
                
                BOOL hasStarted = NO;
                
                for (CLLocation *coordinate in lineString.coordinates)
                {
                    if ( ! hasStarted)
                    {
                        [path moveToLatLong:coordinate.coordinate];
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToLatLong:coordinate.coordinate];
                }
                
                [mapView.contents.overlay addSublayer:path];
            }
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).polygon            &&
                     ((SimpleKMLPlacemark *)feature).style              &&
                     ((SimpleKMLPlacemark *)feature).style.polyStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:mapView.contents] autorelease];
                
                path.lineColor = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;

                if (((SimpleKMLPlacemark *)feature).style.polyStyle.fill)
                    path.fillColor = ((SimpleKMLPlacemark *)feature).style.polyStyle.color;
                
                else
                    path.fillColor = [UIColor clearColor];
                
                path.lineWidth = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                
                SimpleKMLLinearRing *outerBoundary = ((SimpleKMLPlacemark *)feature).polygon.outerBoundary;
                
                BOOL hasStarted = NO;
                
                for (CLLocation *coordinate in outerBoundary.coordinates)
                {
                    if ( ! hasStarted)
                    {
                        [path moveToLatLong:coordinate.coordinate];
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToLatLong:coordinate.coordinate];
                }
                
                [mapView.contents.overlay addSublayer:path];
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
    
    if ([((NSDictionary *)marker.data) objectForKey:@"hasBalloon"])
    {
        SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[((NSDictionary *)marker.data) objectForKey:@"placemark"];
        
        DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        balloonController.name        = placemark.name;
        balloonController.description = placemark.featureDescription;

        UIPopoverController *balloonPopover = [[UIPopoverController alloc] initWithContentViewController:balloonController]; // released by delegate
    
        balloonPopover.popoverContentSize = CGSizeMake(320, 320);
        balloonPopover.delegate = self;
        
        CGRect attachPoint = CGRectMake([mapView.contents latLongToPixel:placemark.point.coordinate].x,
                                        [mapView.contents latLongToPixel:placemark.point.coordinate].y, 
                                        1, 
                                        1);
        
        [balloonPopover presentPopoverFromRect:attachPoint
                                        inView:mapView 
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:NO];
    }
    else
    {
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
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [popoverController release];
}

@end