//
//  PGTDocument.h
//  essaiLoc
//
//  Created by famille on 14/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGTData.h"
#import "PGTMetaData.h"

#define PGT_EXTENSION @"essaiLoc"

@interface PGTDocument : UIDocument

// Data
- (UIImage *)photo;
- (void)setPhoto:(UIImage *)photo;

// Metadata
@property (nonatomic, strong) PGTMetaData * metadata;
- (NSString *) description;
@end
