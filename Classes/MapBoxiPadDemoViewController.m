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
#import "UIImage+DSExtensions.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxTileSetChooserController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kStartingLat   19.5f
#define kStartingLon  -74.0f
#define kStartingZoom   8.0f

#define kStyles [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.20], \
                                          [NSNumber numberWithFloat:0.48], \
                                          [NSNumber numberWithFloat:0.76], \
                                          [NSNumber numberWithFloat:1.04], \
                                          [NSNumber numberWithFloat:1.32], \
                                          [NSNumber numberWithFloat:1.60], \
                                          [NSNumber numberWithFloat:1.88], \
                                          [NSNumber numberWithFloat:2.16], \
                                          [NSNumber numberWithFloat:2.44], \
                                          [NSNumber numberWithFloat:2.72], \
                                          [NSNumber numberWithFloat:3.00], \
                                          nil]

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
    
    NSString *kmlText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"haiti_commune_term" ofType:@"kml"] 
                                                  encoding:NSUTF8StringEncoding 
                                                     error:NULL];
    
    CXMLDocument *kml = [[[CXMLDocument alloc] initWithXMLString:kmlText options:0 error:NULL] autorelease];

    NSArray *nodes = [[[kml rootElement] childAtIndex:1] children];
    
    for (CXMLElement *node in nodes)
    {
        if ([[[node name] lowercaseString] isEqualToString:@"placemark"])
        {
            NSString *placename   = nil;
            NSString *coordinates = nil;
            NSUInteger style      = 0;
            
            for (CXMLElement *subnode in [node children])
            {
                if ([[[subnode name] lowercaseString] isEqualToString:@"name"])
                    placename = [subnode stringValue];
                
                else if ([[[subnode name] lowercaseString] isEqualToString:@"point"])
                    coordinates = [[[subnode elementsForName:@"coordinates"] objectAtIndex:0] stringValue];

                else if ([[[subnode name] lowercaseString] isEqualToString:@"styleurl"])
                    style = [[[subnode stringValue] stringByReplacingOccurrencesOfString:@"#" withString:@""] integerValue];
            }
            
            //NSLog(@"%@ %@ %i", placename, coordinates, style);
            
            NSArray *parts = [coordinates componentsSeparatedByString:@","];
            
            float lon = [[NSString stringWithFormat:@"%@", [parts objectAtIndex:0]] floatValue];
            float lat = [[NSString stringWithFormat:@"%@", [parts objectAtIndex:1]] floatValue];
            
            CLLocationCoordinate2D point;
            
            point.longitude = lon;
            point.latitude  = lat;
            
            UIImage *image = [UIImage imageNamed:@"kml-point.png"];
            
            float multiplier = [[kStyles objectAtIndex:style] floatValue];
            
            int dimension = round(30.0 * multiplier);
            
            UIImage *sizedImage = [UIImage resizeImage:image width:dimension height:dimension];
            UIImage *alphaImage = [UIImage setImage:sizedImage toAlpha:0.6];
            
            RMMarker *marker = [[[RMMarker alloc] initWithUIImage:alphaImage] autorelease];
            
            marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                               @"marker", 
                                                                     placename,                            @"label", 
                                                                     [NSNumber numberWithFloat:0.6],       @"alpha", 
                                                                     [NSNumber numberWithFloat:dimension], @"size", 
                                                                     nil];
            
            [[[RMMarkerManager alloc] initWithContents:mapView.contents] autorelease];
            
            [mapView.contents.markerManager addMarker:marker AtLatLong:point];
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
    float originalSize = [[lastMarkerInfo objectForKey:@"alpha"] floatValue];
    float newAlpha;
    
    if ( ! [lastMarkerInfo objectForKey:@"lastAlpha"] || [[lastMarkerInfo objectForKey:@"lastAlpha"] floatValue] == originalSize)
    {
        newAlpha = 0.1;
        
        [lastMarkerInfo setObject:[NSNumber numberWithFloat:newAlpha] forKey:@"lastAlpha"];
    }

    else
        newAlpha = [[lastMarkerInfo objectForKey:@"lastAlpha"] floatValue] + 0.1;
    
    UIImage *image = [UIImage resizeImage:[UIImage imageNamed:@"kml-point.png"] 
                                    width:[[lastMarkerInfo objectForKey:@"size"] integerValue] 
                                   height:[[lastMarkerInfo objectForKey:@"size"] integerValue]];
    
    [[lastMarkerInfo objectForKey:@"marker"] replaceUIImage:[UIImage setImage:image toAlpha:newAlpha]];
    
    [lastMarkerInfo setObject:[NSNumber numberWithFloat:newAlpha] forKey:@"lastAlpha"];
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
    [self.view addSubview:snapshotView];
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
    [UIView setAnimationDuration:1.2];
    [snapshotView removeFromSuperview];
    [self.view addSubview:mapView];
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
    if ([clickLabel.text isEqualToString:[((NSDictionary *)marker.data) objectForKey:@"label"]])
        return;
    
    [timer invalidate];
    [timer release];
    
    UIImage *image = [UIImage resizeImage:[UIImage imageNamed:@"kml-point.png"] 
                                    width:[[lastMarkerInfo objectForKey:@"size"] integerValue] 
                                   height:[[lastMarkerInfo objectForKey:@"size"] integerValue]];
    
    [[lastMarkerInfo objectForKey:@"marker"] replaceUIImage:[UIImage setImage:image toAlpha:0.6]];
    
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
    
    [lastMarkerInfo release];
    lastMarkerInfo = [[NSMutableDictionary dictionaryWithDictionary:((NSDictionary *)marker.data)] retain];
    
    timer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(pulse:)
                                            userInfo:nil
                                             repeats:YES] retain];
}

@end