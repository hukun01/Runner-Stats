

#import <MapKit/MapKit.h>
#import "CHCSVParser.h"

@interface RSPath : NSObject <MKOverlay>
{
    MKMapPoint *points;
    NSUInteger pointCount;
    NSUInteger pointSpace;
    MKMapRect boundingMapRect;
    CLLocationSpeed *speedArray;
    NSUInteger speedCount;
    NSUInteger speedSpace;
    CLLocationDistance distance;
}

- (BOOL)saveFirstLocation:(CLLocation *)location;
- (void)clearContents;
- (void)saveTmpAsData;
- (BOOL)isValidLocation:(CLLocation *)location;

// Add a location observation. A MKMapRect containing the newly added point
// and the previously added point is returned so that the view can be updated
// in that rectangle.  If the added coordinate has not moved far enough from
// the previously added coordinate it will not be added to the list and 
// MKMapRectNull will be returned.
//
- (MKMapRect)addLocation:(CLLocation *)location;
- (CLLocationSpeed)instantSpeed;

@property (assign, nonatomic) MKMapPoint *points;
@property (assign, nonatomic) NSUInteger pointCount;
@property (assign, nonatomic) CLLocationDistance distance;
@property (assign, nonatomic) CLLocationSpeed *speedArray;
@property(nonatomic, strong) NSString *tmpFile;
@end
