//
//  DSMapBoxDocumentSaveController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxDocumentSaveController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UIImageView *snapshotView;
    IBOutlet UITextField *nameTextField;
}

@property (nonatomic, retain) UIImage *snapshot;
@property (nonatomic, retain) NSString *name;

@end