//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"

@class SimpleKML;

@interface MapBoxiPadDemoViewController : UIViewController <RMMapViewDelegate, UIPopoverControllerDelegate>
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
}

- (IBAction)tappedAllowRotationButton:(id)sender;
- (IBAction)tappedRecenterButton:(id)sender;
- (IBAction)tappedKMLButton:(id)sender;
- (IBAction)tappedTilesButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;

@end