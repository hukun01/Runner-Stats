

#import "RSPath.h"

#define INITIAL_POINT_SPACE 1000
#define TOO_BIG_DISTANCE 50
#define MINIMUM_DELTA_METERS 5.0
#define POINTS_TAG 0
#define SPEEDS_TAG 1

@interface RSPath()
@property(nonatomic, strong) NSString *tmpFile;
@property(nonatomic, strong) NSString *tmpPath;
@property(nonatomic, strong) NSFileManager *fileManager;
@end

@implementation RSPath

@synthesize points, pointCount, speedArray, distance;

- (id)init
{
	self = [super init];
    if (self)
	{
        // Initialize point storage
        pointSpace = INITIAL_POINT_SPACE;
        points = malloc(sizeof(MKMapPoint) * pointSpace);
        pointCount = 0;
        // Initialize instant speeds storage
        speedSpace = INITIAL_POINT_SPACE;
        speedArray = malloc(sizeof(CLLocationSpeed) * speedSpace);
        speedCount = 0;
        // Initialize file management related variables
        self.fileManager = [NSFileManager defaultManager];
        self.tmpPath = NSTemporaryDirectory();
        [self createTmpFile];
    }
    return self;
}
// There is always only one tmpFile in a session, with structure as follows.
// timeInterval(int),speed(double)
- (void)createTmpFile
{
    // Create a new tmpPath for tmp file
    self.tmpFile = [[NSUUID new] UUIDString];
    if (!self.tmpPath) {
        NSLog(@"There is no temp path available.");
        return;
    }
    self.tmpFile = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.csv",self.tmpFile]];
    
    // Create temp file
    if (![self.fileManager createFileAtPath:self.tmpFile contents:nil attributes:nil])
    {
        NSLog(@"Temp creation failed.");
    }
    else
    {
        NSLog(@"Temp creation succeeded %@", self.tmpFile);
    }
}

- (void)clearContents
{
    // Clear points array
    memset(points, 0, sizeof(MKMapPoint) * pointCount);
    // Clear speed array
    memset(speedArray, 0, sizeof(CLLocationSpeed) * speedCount);
    
    NSArray *tmpFiles = [self.fileManager contentsOfDirectoryAtPath:self.tmpPath error:NULL];
    for (NSString *filename in tmpFiles) {
        if ([self.fileManager removeItemAtPath:[self.tmpPath stringByAppendingPathComponent:filename] error:NULL])
        {
            NSLog(@"Delete %@", filename);
        }
        else {
            NSLog(@"Delete temp failed.");
        }
    }
    // Re-create a new empty tmp file
    [self createTmpFile];
}

- (void)saveCurrLocation:(CLLocation *)location
{
    if (![self isValidLocation:location]) {
        return;
    }
    points[0] = MKMapPointForCoordinate([location coordinate]);
    pointCount = 1;
    speedArray[0] = location.speed;
    speedCount = 1;
    
    // Bite off up to 1/4 of the world to draw into.
    
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

- (void)addALine:(NSArray *)newline
{
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.tmpFile];
    [writer writeLineOfFields:newline];
}

- (MKMapRect)addLocation:(CLLocation *)location
{
    MKMapRect updateRect = MKMapRectNull;
    if (![self isValidLocation:location]) {
        return updateRect;
    }
    // Convert a CLLocationCoordinate2D to an MKMapPoint
    MKMapPoint newPoint = MKMapPointForCoordinate([location coordinate]);
    MKMapPoint prevPoint = points[pointCount - 1];
    // Get the distance between this new point and the previous point.
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
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
            [self reallocArrayWithOptions:POINTS_TAG];
        }
        if (speedSpace == speedCount) {
            [self reallocArrayWithOptions:SPEEDS_TAG];
        }
        // Add the new point to the points array
        points[pointCount] = newPoint;
        pointCount++;
        // Add new speed
        speedArray[speedCount] = location.speed;
        speedCount++;
        // Compute MKMapRect bounding prevPoint and newPoint
        double minX = MIN(newPoint.x, prevPoint.x);
        double minY = MIN(newPoint.y, prevPoint.y);
        double maxX = MAX(newPoint.x, prevPoint.x);
        double maxY = MAX(newPoint.y, prevPoint.y);
        
        updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    return updateRect;
}

- (void)reallocArrayWithOptions:(NSUInteger)option
{
    if (option == POINTS_TAG)
    {
        pointSpace *= 2;
        points = realloc(points, sizeof(MKMapPoint) * pointSpace);
    }
    else if (option == SPEEDS_TAG)
    {
        speedSpace *= 2;
        speedArray = realloc(speedArray, sizeof(CLLocationSpeed) * speedSpace);
    }
}

- (BOOL)isValidLocation:(CLLocation *)location
{
    // Skip old info
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) > 10.0) {
        return NO;
    }
    if (location.horizontalAccuracy > TOO_BIG_DISTANCE || location.horizontalAccuracy < 0) {
        return NO;
    }
    if (location.speed < 0) {
        return NO;
    }
    return YES;
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
