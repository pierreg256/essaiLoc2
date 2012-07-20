//
//  PGTCrumbPathView.m
//  essaiLoc
//
//  Created by Pierre Gilot on 17/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTCrumbPathView.h"
#import "PGTCrumbPath.h"
#import "DDLog.h"

@interface PGTCrumbPathView (FileInternal)
- (CGPathRef)newPathForLocations:(NSMutableArray *)points
                   pointCount:(NSUInteger)pointCount
                     clipRect:(MKMapRect)mapRect
                    zoomScale:(MKZoomScale)zoomScale;
@end

@implementation PGTCrumbPathView

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{
    PGTCrumbPath *crumbs = (PGTCrumbPath *)(self.overlay);
    
    CGFloat lineWidth = MKRoadWidthAtZoomScale(zoomScale);
    
    // outset the map rect by the line width so that points just outside
    // of the currently drawn rect are included in the generated path.
    MKMapRect clipRect = MKMapRectInset(mapRect, -lineWidth, -lineWidth);
    
    
    CGPathRef path = [self newPathForLocations:crumbs.crumbs
                                 pointCount:crumbs.crumbs.count
                                   clipRect:clipRect
                                  zoomScale:zoomScale];
    
    if (path != nil)
    {
        CGContextAddPath(context, path);
        CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 0.5f);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, lineWidth);
        CGContextStrokePath(context);
        CGPathRelease(path);
    }
}


@end

@implementation PGTCrumbPathView (FileInternal)

static BOOL lineIntersectsRect(MKMapPoint p0, MKMapPoint p1, MKMapRect r)
{
    double minX = MIN(p0.x, p1.x);
    double minY = MIN(p0.y, p1.y);
    double maxX = MAX(p0.x, p1.x);
    double maxY = MAX(p0.y, p1.y);
    
    MKMapRect r2 = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    return MKMapRectIntersectsRect(r, r2);
}

#define MIN_POINT_DELTA 5.0

- (CGPathRef)newPathForLocations:(NSMutableArray *)points
                      pointCount:(NSUInteger)pointCount
                        clipRect:(MKMapRect)mapRect
                       zoomScale:(MKZoomScale)zoomScale;
{
    // The fastest way to draw a path in an MKOverlayView is to simplify the
    // geometry for the screen by eliding points that are too close together
    // and to omit any line segments that do not intersect the clipping rect.
    // While it is possible to just add all the points and let CoreGraphics
    // handle clipping and flatness, it is much faster to do it yourself:
    //
    if (pointCount < 2)
        return NULL;
    
    CGMutablePathRef path = NULL;
    
    BOOL needsMove = YES;
    
#define POW2(a) ((a) * (a))
    
    // Calculate the minimum distance between any two points by figuring out
    // how many map points correspond to MIN_POINT_DELTA of screen points
    // at the current zoomScale.
    double minPointDelta = MIN_POINT_DELTA / zoomScale;
    double c2 = POW2(minPointDelta);
    
    MKMapPoint point, lastPoint = MKMapPointForCoordinate(((CLLocation*)[points objectAtIndex:0]).coordinate);
    NSUInteger i;
    for (i = 1; i < pointCount - 1; i++)
    {
        point = MKMapPointForCoordinate(((CLLocation*)[points objectAtIndex:i]).coordinate);
        double a2b2 = POW2(point.x - lastPoint.x) + POW2(point.y - lastPoint.y);
        if (a2b2 >= c2) {
            if (lineIntersectsRect(point, lastPoint, mapRect))
            {
                if (!path)
                    path = CGPathCreateMutable();
                if (needsMove)
                {
                    CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
                    CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
                }
                CGPoint cgPoint = [self pointForMapPoint:point];
                CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
            }
            else
            {
                // discontinuity, lift the pen
                needsMove = YES;
            }
            lastPoint = point;
        }
    }
    
#undef POW2
    
    // If the last line segment intersects the mapRect at all, add it unconditionally
    point = MKMapPointForCoordinate(((CLLocation*)[points objectAtIndex:pointCount-1]).coordinate);
    if (lineIntersectsRect(lastPoint, point, mapRect))
    {
        if (!path)
            path = CGPathCreateMutable();
        if (needsMove)
        {
            CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
            CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
        }
        CGPoint cgPoint = [self pointForMapPoint:point];
        CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
    }
    
    return path;
}

@end

