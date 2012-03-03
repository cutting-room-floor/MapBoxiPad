//
//  DSMapBoxShareSheet.h
//  MapBoxiPad
//
//  Created by Justin Miller on 1/17/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

@interface DSMapBoxShareSheet : UIActionSheet

// This API creates a customized UIActionSheet that takes an image creation block and
// a presenting view controller. It presents the user with sharing choices, then when 
// one is selected, obtains an image from the block and shares it accordingly, using
// the view controller if needed to present from modally (Mail, Twitter, etc.)
//
// This avoids a possibly ugly delay while obtaining an image just to show an action
// sheet that may not even get used. 
//
+ (id)shareSheetWithImageCreationBlock:(UIImage *(^)(void))imageCreationBlock modalForViewController:(UIViewController *)presentingViewController;

@end