//
//  DSMapBoxDocumentLoadController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLargeSnapshotView.h"

#import <MessageUI/MessageUI.h>

#define kDSSaveFolderName @"Saved Maps"
#define kDSSaveFileName   @"Saved Map"

@class DSMapBoxDocumentLoadController;

@protocol DSMapBoxDocumentLoadControllerDelegate

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller didLoadDocumentWithName:(NSString *)name;
- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller wantsToSaveDocumentWithName:(NSString *)name;

@end

#pragma mark -

@interface DSMapBoxDocumentLoadController : UIViewController <UIActionSheetDelegate, 
                                                              UIScrollViewDelegate, 
                                                              DSMapBoxLargeSnapshotDelegate, 
                                                              MFMailComposeViewControllerDelegate,
                                                              UIAlertViewDelegate>
{
    IBOutlet UIView *noDocsView;
    IBOutlet UIScrollView *scroller;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *dateLabel;
    IBOutlet UIButton *actionButton;
    IBOutlet UIButton *trashButton;
    id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;
    NSArray *saveFiles;
}

@property (nonatomic, assign) id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;

+ (NSString *)saveFolderPath;

- (IBAction)tappedSaveNowButton:(id)sender;
- (IBAction)tappedSendButton:(id)sender;
- (IBAction)tappedTrashButton:(id)sender;

@end