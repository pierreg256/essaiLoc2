//
//  PGTData.h
//  essaiLoc
//
//  Created by famille on 14/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGTCrumbPath.h"

@interface PGTData : NSObject <NSCoding>

@property (strong) UIImage * photo;
@property (strong) PGTCrumbPath* path;

@end
