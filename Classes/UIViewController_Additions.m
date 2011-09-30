//
//  UIViewController_Additions.m
//  MapBoxiPad
//
//  Created by Justin Miller on 9/30/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "UIViewController_Additions.h"

#import <objc/runtime.h>

static NSString *UIViewControllerExclusiveItems = @"UIViewControllerExclusiveItems";
static NSString *UIViewControllerButtonInfo     = @"UIViewControllerButtonInfo";

@interface UIViewController ()

- (void)dismissManagedItemsExcluding:(id)item;
- (void)actionProxy:(id)sender;

@end

#pragma mark -

@implementation UIViewController (UIViewController_Additions)

- (void)manageExclusiveItem:(id)item
{
    // ensure that we are storing items
    //
    NSMutableArray *items = objc_getAssociatedObject(self, UIViewControllerExclusiveItems);
    
    if ( ! items)
    {
        items = [NSMutableArray array];
        
        objc_setAssociatedObject(self, UIViewControllerExclusiveItems, items, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // add item (if valid) to stored items
    //
    if (item && ! [items containsObject:item])
        [items addObject:item];
    
    // for UIBarButtonItems, become a target/action proxy (if not already)
    //
    if ([item isKindOfClass:[UIBarButtonItem class]] && 
        ((UIBarButtonItem *)item).target && 
        ((UIBarButtonItem *)item).action &&
         ! [((UIBarButtonItem *)item).target isEqual:self] &&
        ((UIBarButtonItem *)item).action != @selector(actionProxy:))
    {
        NSMutableDictionary *info = objc_getAssociatedObject(item, UIViewControllerButtonInfo);
        
        if ( ! info)
        {
            info = [NSMutableDictionary dictionary];
            
            objc_setAssociatedObject(item, UIViewControllerButtonInfo, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        [info setObject:((UIBarButtonItem *)item).target forKey:@"target"];
        [info setObject:NSStringFromSelector(((UIBarButtonItem *)item).action) forKey:@"action"];
        
        ((UIBarButtonItem *)item).target = self;
        ((UIBarButtonItem *)item).action = @selector(actionProxy:);
    }

    // dismiss others
    //
    [self dismissManagedItemsExcluding:item];
}

#pragma mark -

- (void)dismissManagedItemsExcluding:(id)item
{
    NSMutableArray *items = objc_getAssociatedObject(self, UIViewControllerExclusiveItems);

    for (id anItem in items)
    {
        if ([anItem isKindOfClass:[UIPopoverController class]] && ! [anItem isEqual:item])
            [(UIPopoverController *)anItem dismissPopoverAnimated:NO];
        
        else if ([anItem isKindOfClass:[UIActionSheet class]] && ! [anItem isEqual:item])
            [(UIActionSheet *)anItem dismissWithClickedButtonIndex:-1 animated:NO];
    }
}

- (void)actionProxy:(id)sender
{    
    [self dismissManagedItemsExcluding:sender];

    NSMutableDictionary *info = objc_getAssociatedObject(sender, UIViewControllerButtonInfo);
    
    if (info)
    {
        id  target = [info objectForKey:@"target"];
        SEL action = NSSelectorFromString([info objectForKey:@"action"]);
        
        [target performSelector:action withObject:sender];
    }
}

@end