//
//  UIViewController_Additions.m
//  MapBoxiPad
//
//  Created by Justin Miller on 9/30/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "UIViewController_Additions.h"

#import <objc/runtime.h>

static NSString *UIViewControllerExclusiveItem = @"UIViewControllerExclusiveItem";
static NSString *UIViewControllerButtonInfo    = @"UIViewControllerButtonInfo";

@interface UIViewController ()

- (void)showExclusiveItem:(id)item;
- (void)actionProxy:(id)sender;

@end

#pragma mark -

@implementation UIViewController (UIViewController_Additions)

- (void)manageExclusiveItem:(id)item
{
    // show new item, dismissing any old one
    //
    [self showExclusiveItem:item];

    // store new item for dismissal later
    //
    objc_setAssociatedObject(self, (__bridge void *)UIViewControllerExclusiveItem, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // for UIBarButtonItems, become a target/action proxy (if not already)
    //
    if ([item isKindOfClass:[UIBarButtonItem class]] && 
        ((UIBarButtonItem *)item).target && 
        ((UIBarButtonItem *)item).action &&
         ! [((UIBarButtonItem *)item).target isEqual:self] &&
        ((UIBarButtonItem *)item).action != @selector(actionProxy:))
    {
        NSMutableDictionary *info = objc_getAssociatedObject(item, (__bridge void *)UIViewControllerButtonInfo);
        
        if ( ! info)
        {
            info = [NSMutableDictionary dictionary];
            
            objc_setAssociatedObject(item, (__bridge void *)UIViewControllerButtonInfo, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        [info setObject:((UIBarButtonItem *)item).target forKey:@"target"];
        [info setObject:NSStringFromSelector(((UIBarButtonItem *)item).action) forKey:@"action"];
        
        ((UIBarButtonItem *)item).target = self;
        ((UIBarButtonItem *)item).action = @selector(actionProxy:);
    }
}

#pragma mark -

- (void)showExclusiveItem:(id)item
{
    id activeItem = objc_getAssociatedObject(self, (__bridge void *)UIViewControllerExclusiveItem);

    if ([activeItem isKindOfClass:[UIPopoverController class]] && ! [activeItem isEqual:item])
        [(UIPopoverController *)activeItem dismissPopoverAnimated:NO];
    
    else if ([activeItem isKindOfClass:[UIActionSheet class]] && ! [activeItem isEqual:item])
        [(UIActionSheet *)activeItem dismissWithClickedButtonIndex:-1 animated:NO];
}

- (void)actionProxy:(id)sender
{    
    [self showExclusiveItem:sender];

    NSMutableDictionary *info = objc_getAssociatedObject(sender, (__bridge void *)UIViewControllerButtonInfo);
    
    if (info)
    {
        id  target = [info objectForKey:@"target"];
        SEL action = NSSelectorFromString([info objectForKey:@"action"]);
        
        [target performSelector:action withObject:sender];
    }
}

@end