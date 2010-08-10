//
//  DSMapBoxDocumentLoadController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDSSaveFolderName @"Saved Maps"

@class DSMapBoxDocumentLoadController;

@protocol DSMapBoxDocumentLoadControllerDelegate

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller didLoadDocumentWithName:(NSString *)name;

@end

#pragma mark -

@interface DSMapBoxDocumentLoadController : UIViewController <UIAlertViewDelegate>
{
    id <DSMapBoxDocumentLoadControllerDelegate>delegate;
}

@property (nonatomic, assign) id <DSMapBoxDocumentLoadControllerDelegate>delegate;

@end