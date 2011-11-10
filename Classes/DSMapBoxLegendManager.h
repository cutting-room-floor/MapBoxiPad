//
//  DSMapBoxLegendManager.h
//  MapBoxiPad
//
//  Created by Justin Miller on 11/9/11.
//  Copyright (c) 2011 Development Seed. All rights reserved.
//

@interface DSMapBoxLegendManager : NSObject <UIScrollViewDelegate, UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) NSArray *legendSources;

- (id)initWithView:(UIView *)view;

@end