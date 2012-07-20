//
//  PGTData.m
//  essaiLoc
//
//  Created by famille on 14/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTData.h"

@implementation PGTData

@synthesize photo = _photo, path = _path;

- (id)initWithPhoto:(UIImage *)photo andPath:(PGTCrumbPath*)path {
    if ((self = [super init])) {
        self.photo = photo;
        self.path = path;
    }
    return self;
}

- (id)init {
    return [self initWithPhoto:nil andPath:nil];
}

#pragma mark NSCoding

#define kVersionKey @"Version"
#define kPhotoKey @"Photo"
#define kCrumbPathKey @"Crumbs"

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:1 forKey:kVersionKey];
    NSData * photoData = UIImagePNGRepresentation(self.photo);
    [encoder encodeObject:photoData forKey:kPhotoKey];
    [encoder encodeObject:self.path forKey:kCrumbPathKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    [decoder decodeIntForKey:kVersionKey];
    NSData * photoData = [decoder decodeObjectForKey:kPhotoKey];
    UIImage * photo = [UIImage imageWithData:photoData];
    PGTCrumbPath* path = [decoder decodeObjectForKey:kCrumbPathKey];
    return [self initWithPhoto:photo andPath:path];
}

@end
