//
//  DSMapBoxLayerAddTypeController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxLayerAddTypeController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *entryField;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIImageView *successImage;
    NSURLConnection *validationConnection;
    NSMutableData *receivedData;
}

@end