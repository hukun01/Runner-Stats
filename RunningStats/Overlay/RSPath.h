

#import <MapKit/MapKit.h>
#import <pthread.h>

@interface RSPath : NSObject <MKOverlay>
{
    MKMapPoint *points;
    NSUInteger pointCount;
    NSUInteger pointSpace;
    
    MKMapRect boundingMapRect;
    

}

- (void)saveCurrLocation:(CLLocationCoordinate2D)coord;

- (void)clearContents;

// Add a location observation. A MKMapRect containing the newly added point
// and the previously added point is returned so that the view can be updated
// in that rectangle.  If the added coordinate has not moved far enough from
// the previously added coordinate it will not be added to the list and 
// MKMapRectNull will be returned.
//
- (MKMapRect)addCoordinate:(CLLocationCoordinate2D)coord;



// The following properties must only be accessed when holding the read lock
// via lockForReading.  Once you're done accessing the points, release the
// read lock with unlockForReading.
//
@property (readonly) MKMapPoint *points;
@property (readonly) NSUInteger pointCount;



@end
