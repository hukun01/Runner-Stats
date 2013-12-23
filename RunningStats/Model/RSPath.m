

#import "RSPath.h"

#define INITIAL_POINT_SPACE 1000
#define TOO_BIG_DISTANCE 50
#define MINIMUM_DELTA_METERS 5.0

@implementation RSPath

@synthesize points, pointCount, speedArray, distance;

- (id)init
{
	self = [super init];
    if (self)
	{
        // initialize point storage and place this first coordinate in it
        pointSpace = INITIAL_POINT_SPACE;
        points = malloc(sizeof(MKMapPoint) * pointSpace);
        pointCount = 0;
        
        speedSpace = INITIAL_POINT_SPACE;
        speedArray = malloc(sizeof(CLLocationSpeed) * speedSpace);
        speedCount = 0;
    }
    return self;
}

- (void)saveCurrLocation:(CLLocation *)location
{
    points[0] = MKMapPointForCoordinate([location coordinate]);
    pointCount = 1;
    speedArray[0] = location.speed;
    speedCount = 1;
    
    // bite off up to 1/4 of the world to draw into.
    
    MKMapPoint origin = points[0];
    origin.x -= MKMapSizeWorld.width / 8.0;
    origin.y -= MKMapSizeWorld.height / 8.0;
    MKMapSize size = MKMapSizeWorld;
    size.width /= 4.0;
    size.height /= 4.0;
    boundingMapRect = (MKMapRect) { origin, size };
    MKMapRect worldRect = MKMapRectMake(0, 0, MKMapSizeWorld.width, MKMapSizeWorld.height);
    boundingMapRect = MKMapRectIntersection(boundingMapRect, worldRect);
}

- (void)clearContents
{
    memset(points, 0, sizeof(MKMapPoint) * pointCount);
}

- (MKMapRect)addLocation:(CLLocation *)location
{
    // Convert a CLLocationCoordinate2D to an MKMapPoint
    MKMapPoint newPoint = MKMapPointForCoordinate([location coordinate]);
    MKMapPoint prevPoint = points[pointCount - 1];
    
    // Get the distance between this new point and the previous point.
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
    MKMapRect updateRect = MKMapRectNull;
    
    // If the distance is too far, skip it
    if (metersApart > TOO_BIG_DISTANCE) {
        return updateRect;
    }
    
    if (metersApart > MINIMUM_DELTA_METERS)
    {
        distance += metersApart;
        // Grow the points array if necessary
        if (pointSpace == pointCount)
        {
            pointSpace *= 2;
            points = realloc(points, sizeof(MKMapPoint) * pointSpace);
        }
        // Add the new point to the points array
        points[pointCount] = newPoint;
        pointCount++;
        // Add new speed
        if (location.speed >= 0) {
            speedArray[speedCount] = location.speed;
            speedCount++;
        }
        // Compute MKMapRect bounding prevPoint and newPoint
        double minX = MIN(newPoint.x, prevPoint.x);
        double minY = MIN(newPoint.y, prevPoint.y);
        double maxX = MAX(newPoint.x, prevPoint.x);
        double maxY = MAX(newPoint.y, prevPoint.y);
        
        updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    return updateRect;
}

- (CLLocationSpeed)averageSpeed
{
    double result = 0;
    for (int i=0; i<speedCount; ++i) {
        result += speedArray[i];
    }
    return result / speedCount;
}

- (CLLocationSpeed)instantSpeed
{
    return speedArray[speedCount -1];
}

- (CLLocationCoordinate2D)coordinate
{
    return MKCoordinateForMapPoint(points[0]);
}

- (MKMapRect)boundingMapRect
{
    return boundingMapRect;
}

@end
