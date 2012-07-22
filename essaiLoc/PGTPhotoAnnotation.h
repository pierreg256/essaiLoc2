//
//  PGTPhotoAnnotation.h
//  essaiLoc
//
//  Created by famille on 21/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PGTPhotoAnnotation : NSObject <MKAnnotation, NSCoding>

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) UIImage* photo;
@property (nonatomic, strong, readonly) UIImage* thumbnail;
@property CLLocationCoordinate2D coordinate;


-(id)initWithCoordinate2D:(CLLocationCoordinate2D)coordinate;
-(id) initWithCoordinate2D:(CLLocationCoordinate2D)coordinate withPhoto:(UIImage*)photo;

@end
