//
//  PGTEntryCell.m
//  essaiLoc
//
//  Created by famille on 15/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTEntryCell.h"

@implementation PGTEntryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

@synthesize photoImageView;
@synthesize titleTextField;
@synthesize subtitleLabel;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [UIView animateWithDuration:0.1 animations:^{
        if(editing){
            titleTextField.enabled = YES;
            titleTextField.borderStyle = UITextBorderStyleRoundedRect;
        }else{
            titleTextField.enabled = NO;
            titleTextField.borderStyle = UITextBorderStyleNone;
        }
    }];
    
}

@end
