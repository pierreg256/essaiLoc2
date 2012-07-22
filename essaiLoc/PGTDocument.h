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
#import "PGTPhotoAnnotation.h"

#define PGT_EXTENSION @"essaiLoc"

@interface PGTDocument : UIDocument

// Data
- (UIImage *)photo;
- (void)setPhoto:(UIImage *)photo;
- (void)addPhotoAnnotation:(PGTPhotoAnnotation*)annotation;
- (NSMutableArray*)annotations;

- (PGTCrumbPath*)crumbPath;
- (void)startCrumbPathWithLocation:(CLLocation*)location;
//- (void)addLocation:(CLLocation*)location;
//- (void)addPhoto:(UIImage*)photo atIndex:(NSUInteger)index;

// Metadata
@property (nonatomic, strong) PGTMetaData * metadata;
- (NSString *) description;
@end
