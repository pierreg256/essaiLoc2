//
//  PGTEntryCell.h
//  essaiLoc
//
//  Created by famille on 15/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGTEntryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView * photoImageView;
@property (weak, nonatomic) IBOutlet UITextField * titleTextField;
@property (weak, nonatomic) IBOutlet UILabel * subtitleLabel;

@end
