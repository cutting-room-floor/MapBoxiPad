//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

@class RMMapView;
@class DSMapBoxDataOverlayManager;
@class DSMapBoxLayerManager;

@interface MapBoxiPadDemoViewController : UIViewController
{
    IBOutlet RMMapView *mapView;
    IBOutlet UIImageView *watermarkView;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *layersButton;
    IBOutlet UIBarButtonItem *recenterButton;
    UIPopoverController *layersPopover;
    DSMapBoxDataOverlayManager *dataOverlayManager;
    DSMapBoxLayerManager *layerManager;
    CLLocationCoordinate2D postRotationMapCenter;
}

- (void)restoreState;
- (void)saveState;
- (IBAction)tappedRecenterButton:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedLibraryButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;

@end