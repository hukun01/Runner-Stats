

#import "RSPath.h"

#define INITIAL_POINT_SPACE 1000
#define TOO_BIG_DISTANCE 50
#define MINIMUM_DELTA_METERS 5.0
#define POINTS_TAG 0
#define SPEEDS_TAG 1

@interface RSPath()

@property (assign, nonatomic) MKMapPoint *points;
@property (assign, nonatomic) NSUInteger pointSpace;
@property (assign, nonatomic) CLLocationSpeed *speedArray;
@property (assign, nonatomic) NSUInteger speedSpace;
@property (assign, nonatomic) NSUInteger speedCount;

@property (strong, nonatomic) NSString *tmpDocPath;
@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) NSDate *dateOfLastEvent;
@property (strong, nonatomic) NSString *tmpFile;

@end

@implementation RSPath
@synthesize points, pointCount;

- (id)init
{
	self = [super init];
    if (self)
	{
        // Initialize point storage
        self.pointSpace = INITIAL_POINT_SPACE;
        points = malloc(sizeof(MKMapPoint) * self.pointSpace);
        pointCount = 0;
        // Initialize instant speeds storage
        self.speedSpace = INITIAL_POINT_SPACE;
        self.speedArray = malloc(sizeof(CLLocationSpeed) * self.speedSpace);
        self.speedCount = 0;
        self.distance = 0.0;
        // Initialize file management related variables
        self.fileManager = [NSFileManager defaultManager];
        self.tmpDocPath = NSTemporaryDirectory();
        // Initialize timeInterval
        self.dateOfLastEvent = [NSDate date];
    }
    return self;
}
// There is always only one tmpFile in a session, with structure as follows.

// timeInterval(double), currentDistance(double), instantSpeed(double)
- (void)createTmpFile
{
    // Create a new tmpPath for tmp file
    self.tmpFile = [[NSUUID new] UUIDString];
    if (!self.tmpDocPath) {
        NSLog(@"There is no temp path available.");
        return;
    }
    self.tmpFile = [self.tmpDocPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.csv",self.tmpFile]];
    
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
    pointCount = 0;
    // Clear speed array
    memset(self.speedArray, 0, sizeof(CLLocationSpeed) * self.speedCount);
    self.speedCount = 0;
    
    // Reset all data
    self.distance = 0.0;
    
    NSArray *tmpFiles = [self.fileManager contentsOfDirectoryAtPath:self.tmpDocPath error:NULL];
    for (NSString *filename in tmpFiles) {
        if ([self.fileManager removeItemAtPath:[self.tmpDocPath stringByAppendingPathComponent:filename] error:NULL])
        {
            NSLog(@"Delete %@", filename);
        }
        else {
            NSLog(@"Delete temp failed.");
        }
    }
}

- (BOOL)saveFirstLocation:(CLLocation *)location
{
    if (![self isValidLocation:location])
        return NO;
    
    points[0] = MKMapPointForCoordinate([location coordinate]);
    pointCount = 1;
    self.speedArray[0] = location.speed;
    self.speedCount = 1;
    
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
    
    // Create temp file for current session
    [self createTmpFile];
    // Write to temp file
    self.dateOfLastEvent = location.timestamp;
    [self addALineByLocation:location];
    
    return YES;
}
// csv fields
// timeInterval(double, seconds), currentDistance(double, meters), instantSpeed(double, meters/seconds)
- (void)addALineByLocation:(CLLocation *)location
{
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.tmpFile];
    
    double timeInterval = ABS([self.dateOfLastEvent timeIntervalSinceDate:location.timestamp]);
    NSString *timeIntervalStr = [NSString stringWithFormat:@"%.2f", timeInterval];
    NSString *disStr = [NSString stringWithFormat:@"%.2f",[self distance]];
    NSString *instantSpeedStr = [NSString stringWithFormat:@"%.2f", location.speed];
    NSArray *newline = @[timeIntervalStr, disStr, instantSpeedStr];
    
    [writer writeLineOfFields:newline];
    self.dateOfLastEvent = location.timestamp;
    
    NSLog(@"%@",newline);
}

- (MKMapRect)addLocation:(CLLocation *)newlocation
{
    MKMapRect updateRect = MKMapRectNull;
    if (![self isValidLocation:newlocation]) {
        return updateRect;
    }
    // Convert a CLLocationCoordinate2D to an MKMapPoint
    MKMapPoint newPoint = MKMapPointForCoordinate([newlocation coordinate]);
    MKMapPoint prevPoint = points[pointCount - 1];
    // Get the distance between this new point and the previous point.
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
    // If the distance is too far, skip it
    if (metersApart > TOO_BIG_DISTANCE) {
        return updateRect;
    }
    
    if (metersApart > MINIMUM_DELTA_METERS) {
        self.distance += metersApart;
        // Grow the points array if necessary
        if (self.pointSpace == pointCount) {
            [self reallocArrayWithOptions:POINTS_TAG];
        }
        if (self.speedSpace == self.speedCount) {
            [self reallocArrayWithOptions:SPEEDS_TAG];
        }
        // Add the new point to the points array
        points[pointCount] = newPoint;
        pointCount++;
        // Add new speed
        self.speedArray[self.speedCount] = newlocation.speed;
        self.speedCount++;
        // Write to temp file
        [self addALineByLocation:newlocation];
        // Compute MKMapRect bounding prevPoint and newPoint
        double minX = MIN(newPoint.x, prevPoint.x);
        double minY = MIN(newPoint.y, prevPoint.y);
        double maxX = MAX(newPoint.x, prevPoint.x);
        double maxY = MAX(newPoint.y, prevPoint.y);
        
        updateRect = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    else {
        NSLog(@"Too close");
    }
    return updateRect;
}

- (void)reallocArrayWithOptions:(NSUInteger)option
{
    if (option == POINTS_TAG) {
        self.pointSpace *= 2;
        points = realloc(points, sizeof(MKMapPoint) * self.pointSpace);
    }
    else if (option == SPEEDS_TAG) {
        self.speedSpace *= 2;
        self.speedArray = realloc(self.speedArray, sizeof(CLLocationSpeed) * self.speedSpace);
    }
}

- (BOOL)isValidLocation:(CLLocation *)location
{
    if (location.horizontalAccuracy > TOO_BIG_DISTANCE || location.horizontalAccuracy < 0) {
        NSLog(@"horizontal error");
        return NO;
    }
    if (location.speed < 0) {
        NSLog(@"speed too low");
        return NO;
    }
    if (location.speed > 20) {
        NSLog(@"speed too high");
        return NO;
    }
    return YES;
}

- (void)saveTmpAsData
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateformatter setDateFormat: @"yyyy-MM-dd"];
    NSString *recordName = [docsPath stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@.csv",[dateformatter stringFromDate:self.dateOfLastEvent]]];
    // Move tmp file to document directory
    if ([self.fileManager fileExistsAtPath:self.tmpFile]) {
        if ([self.fileManager fileExistsAtPath:recordName]) {
            if(![self.fileManager removeItemAtPath:recordName error:NULL])
                NSLog(@"Remove duplicate file failed.");
            else
                NSLog(@"Remove duplicate file.");
        }
        
        if (![self.fileManager moveItemAtPath:self.tmpFile toPath:recordName error:NULL])
            NSLog(@"Move tmp to doc failed.");
        else
            NSLog(@"Move tmp to doc as %@.", recordName);
    }
    else
        NSLog(@"Tmp file has not been created.");
}

- (BOOL)doesTmpFileExists
{
    return [self.fileManager fileExistsAtPath:[self tmpFile]];
}

- (CLLocationSpeed)instantSpeed
{
    return self.speedArray[self.speedCount -1];
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
