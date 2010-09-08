//
//  DSMapBoxDocumentLoadController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxLargeSnapshotView.h"

#import <MessageUI/MessageUI.h>

#define kDSSaveFolderName @"Saved Maps"

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
}

@property (nonatomic, assign) id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;

- (IBAction)tappedSaveNowButton:(id)sender;
- (IBAction)tappedSendButton:(id)sender;
- (IBAction)tappedTrashButton:(id)sender;

@end