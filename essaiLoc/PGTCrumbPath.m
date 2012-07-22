//
//  PGTCrumbPath.m
//  essaiLoc
//
//  Created by Pierre Gilot on 17/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTCrumbPath.h"
#import "DDLog.h"


#define MINIMUM_DELTA_METERS 5.0

@implementation PGTCrumbPath

@synthesize crumbs = _crumbs, boundingMapRect = _boundingMapRect;

- (id)initWithCenterLocation:(CLLocation*)location
{
	self = [super init];
    if (self)
	{
        self.crumbs = [[NSMutableArray alloc] initWithCapacity:1000];
        [self.crumbs addObject:location];
                
        // bite off up to 1/4 of the world to draw into.
        MKMapPoint origin = MKMapPointForCoordinate(((CLLocation*)[self.crumbs objectAtIndex:0]).coordinate);
        origin.x -= MKMapSizeWorld.width / 8.0;
        origin.y -= MKMapSizeWorld.height / 8.0;
        MKMapSize size = MKMapSizeWorld;
        size.width /= 4.0;
        size.height /= 4.0;
        _boundingMapRect = (MKMapRect) { origin, size };
        MKMapRect worldRect = MKMapRectMake(0, 0, MKMapSizeWorld.width, MKMapSizeWorld.height);
        _boundingMapRect = MKMapRectIntersection(_boundingMapRect, worldRect);
        
    }
    return self;
}

- (CLLocation*)getLocationForIndex:(NSUInteger)index
{
    if ((index>0) && (index<=self.crumbs.count)) {
        return [self.crumbs objectAtIndex:index];
    } else {
        return nil;
    }
        
}

- (MKMapRect)addLocation:(CLLocation *)location
{
    
    // Convert a CLLocationCoordinate2D to an MKMapPoint
    MKMapPoint newPoint = MKMapPointForCoordinate(location.coordinate);
    MKMapPoint prevPoint = MKMapPointForCoordinate(((CLLocation*)[self.crumbs objectAtIndex:self.crumbs.count-1]).coordinate);
    
    // Get the distance between this new point and the previous point.
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);

    MKMapRect updateRect = MKMapRectNull;
    
    if (metersApart > MINIMUM_DELTA_METERS)
    {
        // Add the new point to the points array
        [self.crumbs addObject:location];
        
        // Compute MKMapRect bounding prevPoint and newPoint
        double minX = MIN(newPoint.x, prevPoint.x);
        double minY = MIN(newPoint.y, prevPoint.y);
        double maxX = MAX(newPoint.x, prevPoint.x);
        double maxY = MAX(newPoint.y, prevPoint.y);
        
        updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }
        
    return updateRect;
}

#pragma mark - MKOverlay protocol methods
- (CLLocationCoordinate2D)coordinate
{
    return ((CLLocation*)[self.crumbs objectAtIndex:0]).coordinate;
}

#pragma mark - NSCoding Protocol methods

#define kCrumbCountKey @"crumb_count"
#define kCrumbIndexKey @"crumb_index_%05d"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (self.crumbs && self.crumbs.count>0)
    {
        [aCoder encodeObject:[NSNumber numberWithInt:self.crumbs.count] forKey:kCrumbCountKey];
        for (int i=0; i<self.crumbs.count; i++) {
            [aCoder encodeObject:[self.crumbs objectAtIndex:i] forKey:[NSString stringWithFormat:kCrumbIndexKey, i]];
        }
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSNumber* count = [aDecoder decodeObjectForKey:kCrumbCountKey];
    if (count) {
        CLLocation* location = [aDecoder decodeObjectForKey:[NSString stringWithFormat:kCrumbIndexKey, 0]];
        PGTCrumbPath* path = [self initWithCenterLocation:location];
        
        for (int i = 0; i<[count integerValue]; i++) {
            [path addLocation:[aDecoder decodeObjectForKey:[NSString stringWithFormat:kCrumbIndexKey, i]]];
        }
        return path;
    }
    
    return nil;
}


@end
