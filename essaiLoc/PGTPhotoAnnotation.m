//
//  PGTPhotoAnnotation.m
//  essaiLoc
//
//  Created by famille on 21/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTPhotoAnnotation.h"
#import "UIImageExtras.h"
#import "DDLog.h"

@interface PGTPhotoAnnotation ()

@property (nonatomic, strong) UIImage* thumb;

@end

@implementation PGTPhotoAnnotation

@synthesize name = _name, description = _description, photo = _photo, coordinate = _coordinate, thumb = _thumb;

-(id)initWithCoordinate2D:(CLLocationCoordinate2D)coordinate photo:(UIImage *)photo name:(NSString*)name description:(NSString*)desc
{
    if (self=[super init]) {
        self.coordinate = coordinate;
        self.photo = photo;
        self.name = name;
        self.description = desc;
    }
    
    return self;
}

-(id)initWithCoordinate2D:(CLLocationCoordinate2D)coordinate withPhoto:(UIImage *)photo
{
    if (self=[super init]) {
        self.coordinate = coordinate;
        self.photo = photo;
    }
    
    return self;
}

-(id)initWithCoordinate2D:(CLLocationCoordinate2D)coordinate
{
    return [self initWithCoordinate2D:coordinate withPhoto:nil];
}

-(UIImage*) thumbnail
{
    if ((!_thumb) && (_photo))
    {
        self.thumb = [self.photo imageByScalingAndCroppingForSize:CGSizeMake(50, 50)];
    }
    
    return _thumb;
}

-(NSString*)title
{
    DDLog(@"annotation title: %@", self.name);
    return self.name;
}

-(NSString*)subtitle
{
    return self.description;
}

#pragma mark - NSCoding properties
#define kVersionKey @"Version"
#define kPhotoKey @"Photo"
#define kNameKey @"Name"
#define kDescriptionKey @"Description"
#define kCoordinateKey @"Coordinate"

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:1 forKey:kVersionKey];
    NSData * photoData = UIImagePNGRepresentation(self.photo);
    [encoder encodeObject:photoData forKey:kPhotoKey];
    
    [encoder encodeObject:self.name forKey:kNameKey];
    
    [encoder encodeObject:self.description forKey:kDescriptionKey];
    
    [encoder encodeObject:[[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude] forKey:kCoordinateKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    [decoder decodeIntForKey:kVersionKey];
    
    NSData * photoData = [decoder decodeObjectForKey:kPhotoKey];
    UIImage * photo = [UIImage imageWithData:photoData];
    
    NSString* name = [decoder decodeObjectForKey:kNameKey];
    NSString* desc = [decoder decodeObjectForKey:kDescriptionKey];
    CLLocationCoordinate2D coord = ((CLLocation*) [decoder decodeObjectForKey:kCoordinateKey]).coordinate;

    return [self initWithCoordinate2D:coord photo:photo name:name description:desc];
}



@end
