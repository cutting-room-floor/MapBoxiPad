//
//  DSMapBoxForwardingView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/17/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxForwardingView.h"

@implementation DSMapBoxForwardingView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return [self pointInside:point withEvent:event] ? recipientView : nil;
}

@end