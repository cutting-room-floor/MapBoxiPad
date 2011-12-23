//
//  DSMapBoxPopoverController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMFoundation.h"

@interface DSMapBoxPopoverController : UIPopoverController

@property (nonatomic, weak) UIView *presentingView;
@property (nonatomic, assign) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, assign) RMProjectedPoint projectedPoint;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;

@end