//
//  UIAlertView_Additions.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/10/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "UIAlertView_Additions.h"

#include <objc/runtime.h>

NSString *const UIAlertViewAdditionsContext = @"UIAlertViewAdditionsContext";

@implementation UIAlertView (UIAlertView_Additions)

- (void)setContext:(id)context
{
    objc_setAssociatedObject(self, UIAlertViewAdditionsContext, context, OBJC_ASSOCIATION_ASSIGN);
}

- (id)context
{
    return objc_getAssociatedObject(self, UIAlertViewAdditionsContext);
}

@end