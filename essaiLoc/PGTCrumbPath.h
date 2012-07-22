//
//  PGTCrumbPath.h
//  essaiLoc
//
//  Created by Pierre Gilot on 17/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PGTCrumbPath : NSObject <MKOverlay, NSCoding>

@property (atomic, strong) NSMutableArray* crumbs;
@property (nonatomic, readonly) MKMapRect boudingMapRect;

// Initialize the CrumbPath with the starting coordinate.
// The CrumbPath's boundingMapRect will be set to a sufficiently large square
// centered on the starting coordinate.
//
- (id)initWithCenterLocation:(CLLocation*)location;

// Add a location observation. A MKMapRect containing the newly added point
// and the previously added point is returned so that the view can be updated
// in that rectangle.  If the added coordinate has not moved far enough from
// the previously added coordinate it will not be added to the list and
// MKMapRectNull will be returned.
//
- (MKMapRect)addLocation:(CLLocation*)location;
- (CLLocation*)getLocationForIndex:(NSUInteger)index;

@end
