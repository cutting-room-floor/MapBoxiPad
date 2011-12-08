//
//  DSMapBoxLegendManager.h
//  MapBoxiPad
//
//  Created by Justin Miller on 11/9/11.
//  Copyright (c) 2011 Development Seed. All rights reserved.
//

#define kDSMapBoxLegendManagerMaxWidth  350
#define kDSMapBoxLegendManagerMaxHeight 650

@interface DSMapBoxLegendManager : NSObject <UIScrollViewDelegate, UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) NSArray *legendSources;

- (id)initWithFrame:(CGRect)frame parentView:(UIView *)view;

@end