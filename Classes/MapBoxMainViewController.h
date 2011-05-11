//
//  MapBoxMainViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxDocumentLoadController.h"
#import "DSMapBoxLayerController.h"
#import "DSMapBoxLayerManager.h"

#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>

@class DSMapView;
@class DSMapBoxDataOverlayManager;
@class DSMapBoxLayerManager;
@class DSMapBoxDocumentSaveController;
@class Reachability;

@interface MapBoxMainViewController : UIViewController <UIActionSheetDelegate, 
                                                        DSMapBoxDocumentLoadControllerDelegate, 
                                                        DSDataLayerHandlerDelegate,
                                                        UIAlertViewDelegate, 
                                                        MFMailComposeViewControllerDelegate,
                                                        DSMapBoxLayerControllerDelegate>
{
    IBOutlet DSMapView *mapView;
    IBOutlet UILabel *attributionLabel;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIBarButtonItem *layersButton;
    IBOutlet UIBarButtonItem *clusteringButton;
    UIPopoverController *layersPopover;
    DSMapBoxDataOverlayManager *dataOverlayManager;
    DSMapBoxLayerManager *layerManager;
    CLLocationCoordinate2D postRotationMapCenter;
    DSMapBoxDocumentSaveController *saveController;
    DSMapBoxDocumentLoadController *loadController;
    UIActionSheet *documentsActionSheet;
    
    @private
        NSString *badParsePath;
        Reachability *reachability;
        NSDate *lastLayerAlertDate;
}

@property (nonatomic, retain) NSString *badParsePath;
@property (nonatomic, retain) NSDate *lastLayerAlertDate;

- (void)restoreState:(id)sender;
- (void)saveState:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedClusteringButton:(id)sender;
- (IBAction)tappedDocumentsButton:(id)sender;
- (IBAction)tappedHelpButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;
- (void)openRSSFile:(NSURL *)fileURL;

@end