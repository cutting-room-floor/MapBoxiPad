//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import "DSMapBoxGeoRSSBrowserController.h"

@class SimpleKML;
@class DSMapBoxOverlayManager;

@interface MapBoxiPadDemoViewController : UIViewController <RMMapViewDelegate, UIPopoverControllerDelegate, DSMapBoxGeoRSSBrowserControllerDelegate>
{
    IBOutlet RMMapView *mapView;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *kmlButton;
    IBOutlet UIBarButtonItem *rotationButton;
    IBOutlet UIBarButtonItem *recenterButton;
    IBOutlet UIBarButtonItem *tilesButton;
    IBOutlet UILabel *clickLabel;
    IBOutlet UIImageView *clickStripe;
    UIPopoverController *popover;
    NSMutableDictionary *lastMarkerInfo;
    NSTimer *timer;
    SimpleKML *kml;
    DSMapBoxOverlayManager *overlayManager;
}

- (IBAction)tappedAllowRotationButton:(id)sender;
- (IBAction)tappedRecenterButton:(id)sender;
- (IBAction)tappedKMLButton:(id)sender;
- (IBAction)tappedGeoRSSButton:(id)sender;
- (IBAction)tappedTilesButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;

@end