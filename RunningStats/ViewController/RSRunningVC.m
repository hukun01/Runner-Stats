//
//  RSFirstViewController.m
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRunningVC.h"
#import "RSStatsFirstVC.h"

#define DISCARD_ALERT_TAG 0
#define SAVE_ALERT_TAG 1
#define MAP_REGION_SIZE 330

@interface RSRunningVC ()
@property (strong, nonatomic) IBOutlet MKMapView *map;
// TextField to display instant data
@property (strong, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong, nonatomic) IBOutlet UILabel *currSpeedLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *avgSpeedLabel;
// Data
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic, setter = setSpeed:) CLLocationSpeed speed;
@property (assign, nonatomic, setter = setDistance:) CLLocationDistance distance;
@property (assign, nonatomic, setter = setAvgSpeed:) CLLocationSpeed avgSpeed;
@property (assign, nonatomic, setter = setSeconds:) NSInteger sessionSeconds;
@property (assign, nonatomic) BOOL isRunning;
@property (strong, nonatomic) CLLocation *currLocation;
@property (strong, nonatomic) NSDate *startDate;
// Buttons
@property (strong, nonatomic) IBOutlet UIButton *startButton;
// Stop and discard a session
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
// Stop and save a session
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
// Others
@property (strong, nonatomic) RSRecordManager *recordManager;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) RSPath *path;
@property (strong, nonatomic) MKPolylineRenderer *pathRenderer;

@property (strong, nonatomic) IBOutlet UILabel *test_statusLabel;


@end

@implementation RSRunningVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.map.delegate = self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.isRunning) {
        [self restoreUI];
    }
    
    [self renewMapRegion];
    self.map.showsUserLocation = YES;
    self.currLocation = [self.locationManager location];
    
    //debug
    if (!self.map.userLocationVisible) {
        NSLog(@"User not in the screen.");
    }
}

- (void)setUp
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = 3.0;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    // data
    [self resetData];
    // TO-DO: Drop the initial invalid location
    _currLocation = [_locationManager location];
    
    self.isRunning = NO;
    
    // Create a record if not exist
    _recordManager = [[RSRecordManager alloc] init];
    
    // debug
//    if (![[NSFileManager defaultManager] removeItemAtPath:[self.recordManager recordPath] error:NULL])
//        NSLog(@"remove failed");
//    if (![_recordManager createRecord])
//        NSLog(@"Create record.csv failed.");
}

# pragma mark - Start Session
- (IBAction)startSession:(id)sender
{
    self.isRunning = YES;
    [self.locationManager startUpdatingLocation];
    // Clear the data of last event
    if ([[self.map overlays] count] != 0) {
        [self.map removeOverlays:[self.map overlays]];
        NSLog(@"Remove overlays");
    }
    [self.path clearContents];
    [self resetData];
    
    //[self.locationManager startUpdatingLocation];
    self.startDate = [NSDate date];
    [self renewMapRegion];
    // start a timer
    [self startTimer];
    
    // Change accessibility of some UI elements
    self.startButton.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    self.saveButton.hidden = NO;
    self.stopButton.hidden = NO;
    self.map.zoomEnabled = NO;
    
    // debug
    NSLog(@"Start Session:");
    NSArray *allRecords = [self.recordManager readRecord];
    int i=0;
    for (NSString *s in allRecords) {
        NSLog(@"%d: %@",i++,[s description]);
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    _map.centerCoordinate = userLocation.location.coordinate;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    if (!self.path) {
        self.path = [[RSPath alloc] init];
    }
    if ([self.path pointCount] == 0) {
        self.currLocation = newLocation;
        if (![self.path saveFirstLocation:self.currLocation]) {
            self.test_statusLabel.text = @"No valid location";
        }
        else {
            [self.map addOverlay:self.path];
            self.test_statusLabel.text = @"Add overlay";
        }
    }
    if ((self.currLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
        (self.currLocation.coordinate.longitude != newLocation.coordinate.longitude)) {
        MKMapRect updateRect = [self.path addLocation:newLocation];
        
        if (!MKMapRectIsNull(updateRect)) {
            // Update map and speed and distance textfields
            // Map
            // Compute the currently visible map zoom scale
            MKZoomScale currentZoomScale = (CGFloat)(self.map.bounds.size.width / self.map.visibleMapRect.size.width);
            // Find out the line width at this zoom scale and outset the updateRect by that amount
            CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
            updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
            // Ask the overlay view to update just the changed area.
            [self.pathRenderer setNeedsDisplayInMapRect:updateRect];
            // Update data
            self.distance = [self.path distance] / 1000;
            self.speed = 3.6 * [self.path instantSpeed];
            // Move map with user location
            self.currLocation = newLocation;
            
            //debug
            self.test_statusLabel.text = [NSString stringWithFormat:@"%.4f, %.4f", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
        }
    }
    [self renewMapRegion];
    NSTimeInterval duration = ABS([self.startDate timeIntervalSinceNow]);
    self.avgSpeed = 3.6 * [self.path distance] / duration;
}

#pragma mark - Discard and Save Session
- (IBAction)discardSession:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Discard?" message:@"Do you want to stop and discard this session?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Discard", nil];
    alert.tag = DISCARD_ALERT_TAG;
    [alert show];
}

- (IBAction)saveSession:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save?" message:@"Do you want to stop and save this session?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.tag = SAVE_ALERT_TAG;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        // First to stop session
        [self stopSession];
        // Discard session
        if (alertView.tag == DISCARD_ALERT_TAG)
        {
            // TO-DO: delete tmp files
            // Remove overlay, clear path
            [self.map removeOverlays:[self.map overlays]];
            [self.path clearContents];
            [self resetData];
        }
        // save session
        else if (alertView.tag == SAVE_ALERT_TAG)
        {
            // Save current session
            // TO-DO: save tmp files to disk
            // Remain all data
            // make it unable to zoom
            [self saveSessionAsRecord];
            [self.path saveTmpAsData];
        }
    }
}

- (void)stopSession
{
    [self.locationManager stopUpdatingLocation];
    [self stopTimer];
    [self restoreUI];
    self.isRunning = NO;
}

- (void)resetData
{
    self.speed = 0.0;
    self.distance = 0.0;
    self.avgSpeed = 0.0;
    self.sessionSeconds = 0;
}

- (void)restoreUI
{
    // Restore buttons
    self.startButton.hidden = NO;
    self.stopButton.hidden = YES;
    self.saveButton.hidden = YES;
    self.tabBarController.tabBar.hidden = NO;
    self.map.zoomEnabled = YES;
}

- (void)stopTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)saveSessionAsRecord
{
    if (![self.path doesTmpFileExists]) {
        NSLog(@"Temp file not exists, nonvalid session.");
        return;
    }
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateformatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSTimeInterval duration = ABS([self.startDate timeIntervalSinceNow]);
    NSString *durStr = [NSString stringWithFormat:@"%d", (int)duration];
    NSString *startDateString = [dateformatter stringFromDate:self.startDate];
    CLLocationDistance finalDistance = [self.path distance];
    finalDistance /= 1000;
    NSString *disStr;
    if (finalDistance > 10.0) {
        disStr = [NSString stringWithFormat:@"%.1f",finalDistance];
    }
    else {
        disStr = [NSString stringWithFormat:@"%.2f",finalDistance];
    }
    
    NSString *avgSpdStr = [NSString stringWithFormat:@"%.2f",3.6 * [self.path distance] / duration];
    
    NSArray *newRecord = @[startDateString, disStr, durStr, avgSpdStr];
    [self.recordManager addALine:newRecord];

    //debug
    self.test_statusLabel.text = [NSString stringWithFormat:@"%@", newRecord];
}

#pragma mark - Stable utility functions
- (void)renewMapRegion
{
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.map.userLocation.coordinate, MAP_REGION_SIZE, MAP_REGION_SIZE);
    [self.map setRegion:region animated:YES];
}

- (void)setSpeed:(CLLocationSpeed)speed
{
    _speed = speed;
    if (speed > 10.0) {
        self.currSpeedLabel.text = [NSString stringWithFormat:@"%.1f", speed];
    }
    else {
        self.currSpeedLabel.text = [NSString stringWithFormat:@"%.2f", speed];
    }
}

- (void)setDistance:(CLLocationDistance)distance
{
    _distance = distance;
    if (distance > 10.0) {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.1f", distance];
    }
    else {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.2f", distance];
    }
}

- (void)setAvgSpeed:(CLLocationSpeed)avgSpeed
{
    _avgSpeed = avgSpeed;
    if (avgSpeed > 10.0) {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.1f", avgSpeed];
    }
    else {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.2f", avgSpeed];
    }
}

- (void)setSeconds:(NSInteger)sessionSeconds
{
    _sessionSeconds = sessionSeconds;
    self.timerLabel.text = [self.recordManager timeFormatted:sessionSeconds withOption:FORMAT_HHMMSS];
}

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)timerTick
{
    self.sessionSeconds += 1;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
    if (!self.pathRenderer) {
        _pathRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        self.pathRenderer.strokeColor = [[UIColor alloc] initWithRed:66.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:0.75];
        self.pathRenderer.lineWidth = 6.5;
    }
    return self.pathRenderer;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
@end
