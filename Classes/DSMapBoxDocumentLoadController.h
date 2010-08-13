//
//  DSMapBoxDocumentLoadController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxDocumentScrollView.h"

#define kDSSaveFolderName @"Saved Maps"

@class DSMapBoxDocumentLoadController;

@protocol DSMapBoxDocumentLoadControllerDelegate

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller didLoadDocumentWithName:(NSString *)name;

@end

#pragma mark -

@interface DSMapBoxDocumentLoadController : UIViewController <UIActionSheetDelegate, DSMapBoxDocumentScrollViewDelegate>
{
    IBOutlet DSMapBoxDocumentScrollView *scroller;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *dateLabel;
    id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;
}

@property (nonatomic, assign) id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;

- (IBAction)tappedTrashButton:(id)sender;

@end