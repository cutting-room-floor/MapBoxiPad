//
//  DSMapBoxDownloadTableViewCell.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@class SSPieProgressView;

@interface DSMapBoxDownloadTableViewCell : UITableViewCell

@property (nonatomic, readonly, strong) IBOutlet SSPieProgressView *pie;
@property (nonatomic, readonly, strong) IBOutlet UILabel *primaryLabel;
@property (nonatomic, readonly, strong) IBOutlet UILabel *secondaryLabel;
@property (nonatomic, assign) BOOL isPaused;

@end