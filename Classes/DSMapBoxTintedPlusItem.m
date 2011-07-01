//
//  DSMapBoxTintedPlusItem.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/1/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxTintedPlusItem.h"

@implementation DSMapBoxTintedPlusItem

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTitle:@"" target:target action:action];

    if (self)
    {
        UIButton *tintedButton = ((UIButton *)self.customView);

        [tintedButton setImage:[UIImage imageNamed:@"plus_button.png"] forState:UIControlStateNormal];
        
        tintedButton.bounds = CGRectMake(0, 0, 31, 30);
    }
    
    return self;
}

@end