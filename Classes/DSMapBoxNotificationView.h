//
//  DSMapBoxNotificationView.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/2/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxNotificationView : UIView
{
    UILabel *label;
}

@property (nonatomic, assign) NSString *message;

+ (id)notificationWithMessage:(NSString *)message;

@end