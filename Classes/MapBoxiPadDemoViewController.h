//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxGeoRSSBrowserController.h"

@class RMMapView;
@class DSMapBoxDataOverlayManager;
@class DSMapBoxLayerManager;

@interface MapBoxiPadDemoViewController : UIViewController <DSMapBoxGeoRSSBrowserControllerDelegate>
{
    IBOutlet RMMapView *mapView;
    IBOutlet UIImageView *watermarkView;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *layersButton;
    IBOutlet UIBarButtonItem *recenterButton;
    IBOutlet UIBarButtonItem *tilesButton;
    UIPopoverController *layersPopover;
    UIPopoverController *tilesPopover;
    DSMapBoxDataOverlayManager *dataOverlayManager;
    DSMapBoxLayerManager *layerManager;
}

- (IBAction)tappedRecenterButton:(id)sender;
- (IBAction)tappedGeoRSSButton:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedLibraryButton:(id)sender;
- (IBAction)tappedTilesButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;

@end