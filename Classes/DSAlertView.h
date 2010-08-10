//
//  DSAlertView.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/10/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSAlertView : UIAlertView
{
    id contextInfo;
}

@property (nonatomic, retain) id contextInfo;

@end