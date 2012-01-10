//
//  DSMapBoxDownloadTableViewCell.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@interface DSMapBoxDownloadTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *primaryLabel;
@property (nonatomic, strong) IBOutlet UILabel *secondaryLabel;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL isIndeterminate;
@property (nonatomic, assign) BOOL isPaused;

@end