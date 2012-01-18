//
//  DSMapBoxShareSheet.h
//  MapBoxiPad
//
//  Created by Justin Miller on 1/17/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

@interface DSMapBoxShareSheet : UIActionSheet

+ (id)shareSheetForImageHandler:(UIImage *(^)(void))imageHandler withViewController:(UIViewController *)viewController;

@end