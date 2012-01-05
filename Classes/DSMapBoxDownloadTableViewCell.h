//
//  DSMapBoxDownloadTableViewCell.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSPieProgressView;

@interface DSMapBoxDownloadTableViewCell : UITableViewCell
{
    UIColor *originalPrimaryLabelTextColor;
}

@property (nonatomic, readonly, retain) IBOutlet SSPieProgressView *pie;
@property (nonatomic, readonly, retain) IBOutlet UILabel *primaryLabel;
@property (nonatomic, readonly, retain) IBOutlet UILabel *secondaryLabel;
@property (nonatomic, assign) BOOL isPaused;

@end