//
//  DSMapBoxForwardingView.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/17/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxForwardingView.h"

@implementation DSMapBoxForwardingView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return [self pointInside:point withEvent:event] ? recipientView : nil;
}

@end