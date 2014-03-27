

#import <MapKit/MapKit.h>
#import "CHCSVParser.h"
#import "RSRecordManager.h"

@interface RSPath : NSObject <MKOverlay>
{
    MKMapPoint *points;
    NSUInteger pointCount;
    MKMapRect boundingMapRect;
}

- (BOOL)saveFirstLocation:(CLLocation *)location;
- (void)clearContents;
- (void)saveTmpDataAsRecord;
- (BOOL)isValidLocation:(CLLocation *)location;

// Add a location observation. A MKMapRect containing the newly added point
// and the previously added point is returned so that the view can be updated
// in that rectangle.  If the added coordinate has not moved far enough from
// the previously added coordinate it will not be added to the list and 
// MKMapRectNull will be returned.
//
- (MKMapRect)addLocation:(CLLocation *)newlocation;
- (CLLocationSpeed)instantSpeed;

@property (assign, nonatomic) NSUInteger pointCount;
@property (assign, nonatomic) CLLocationDistance distance;
@property (strong, nonatomic) NSMutableArray *runningData;
@end
