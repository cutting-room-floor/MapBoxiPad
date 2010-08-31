//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxDocumentLoadController.h"
#import "DSMapBoxLayerManager.h"

#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>

@class RMMapView;
@class DSMapBoxDataOverlayManager;
@class DSMapBoxLayerManager;
@class DSMapBoxDocumentSaveController;

@interface MapBoxiPadDemoViewController : UIViewController <UIActionSheetDelegate, 
                                                            DSMapBoxDocumentLoadControllerDelegate, 
                                                            DSDataLayerHandlerDelegate,
                                                            UIAlertViewDelegate, 
                                                            MFMailComposeViewControllerDelegate>
{
    IBOutlet RMMapView *mapView;
    IBOutlet UIImageView *watermarkView;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *layersButton;
    IBOutlet UIBarButtonItem *clusteringButton;
    UIPopoverController *layersPopover;
    DSMapBoxDataOverlayManager *dataOverlayManager;
    DSMapBoxLayerManager *layerManager;
    CLLocationCoordinate2D postRotationMapCenter;
    DSMapBoxDocumentSaveController *saveController;
    DSMapBoxDocumentLoadController *loadController;
    
    @private
        NSString *badParsePath;
}

@property (nonatomic, retain) NSString *badParsePath;

- (void)restoreState:(id)sender;
- (void)saveState:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedClusteringButton:(id)sender;
- (IBAction)tappedDocumentsButton:(id)sender;
- (IBAction)tappedLibraryButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;

@end