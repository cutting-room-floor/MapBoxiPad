//
//  DSMapBoxTintedBarButtonItem.h
//  MapBoxiPad
//
//  Created by Justin Miller on 6/30/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@interface DSMapBoxTintedBarButtonItem : UIBarButtonItem
{
    @private
    
    UIButton *tintedButton;
}

- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end