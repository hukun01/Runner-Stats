//
//  RSFirstViewController.m
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRunningVC.h"
#import "RSPath.h"

#define DISCARD_ALERT_TAG 0
#define SAVE_ALERT_TAG 1

@interface RSRunningVC ()
@property (strong, nonatomic) IBOutlet MKMapView *map;
// TextField to display instant data
@property (strong, nonatomic) IBOutlet UITextField *currSpeedTxt;
@property (strong, nonatomic) IBOutlet UITextField *distanceTxt;
@property (strong, nonatomic) IBOutlet UITextField *avgSpeedTxt;

// Start a session
@property (strong, nonatomic) IBOutlet UIButton *startButton;
// Stop and discard a session
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
// Stop and save a session
@property (strong, nonatomic) IBOutlet UIButton *saveButton;

@property (nonatomic, strong) RSRecordManager *recordManager;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) RSPath *path;
@property (nonatomic, strong) MKPolylineRenderer *pathRenderer;

@end

@implementation RSRunningVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUp];
}

- (void)setUp
{
    // locationManager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //可能需要防抖动
    currLocation = [self.locationManager location];
    // map
    self.map.showsUserLocation = YES;
    self.map.delegate = self;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currLocation.coordinate, 1500, 1500);
    [self.map setRegion:region animated:YES];
    // path
    self.path = [[RSPath alloc] init];
    // UI
    self.saveButton.hidden = YES;
    self.stopButton.hidden = YES;
    
    self.recordManager = [[RSRecordManager alloc] init];
    [self.recordManager createRecord];
}

- (IBAction)startSession:(id)sender
{
    [self.locationManager startUpdatingLocation];
    [self.path saveCurrLocation:currLocation.coordinate];
    [self.map addOverlay:self.path];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currLocation.coordinate, 500, 500);
    [self.map setRegion:region animated:YES];
    //debug
    self.avgSpeedTxt.text =  @"Path added.";
    
    self.startButton.hidden = YES;
    self.stopButton.hidden = NO;
    self.saveButton.hidden = NO;
}

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

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // First to stop session
        [self stopSession];
        // Discard session
        if (alertView.tag == DISCARD_ALERT_TAG) {
            // TO-DO: delete tmp files
            // Remove overlay, clear path
            [self.map removeOverlay:self.path];
            [self.path clearContents];
            //debug
            self.avgSpeedTxt.text =  @"Path deleted.";
        }
        // save session
        else if (alertView.tag == SAVE_ALERT_TAG) {
            // Save current session
            // TO-DO: save tmp files to disk
        }
    }
}

- (void)stopSession
{
    [self.locationManager stopUpdatingLocation];
    self.startButton.hidden = NO;
    self.stopButton.hidden = YES;
    self.saveButton.hidden = YES;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
//    if (!self.path) {
//        self.path = [[RSPath alloc] initWithCenterCoordinate:currLocation.coordinate];
//        [self.map addOverlay:self.path];
//        //debug
//        self.avgSpeedTxt.text =  @"Path added.";
//        
//        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currLocation.coordinate, 1000, 1000);
//        [self.map setRegion:region animated:YES];
//    }
//    else {
        CLLocation *newLocation = [locations lastObject];
        if ((currLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
            (currLocation.coordinate.longitude != newLocation.coordinate.longitude))
        {            
            MKMapRect updateRect = [self.path addCoordinate:newLocation.coordinate];
            
            if (!MKMapRectIsNull(updateRect))
            {
                // Update map and speed and distance textfields
                // Map
                // Compute the currently visible map zoom scale
                MKZoomScale currentZoomScale = (CGFloat)(self.map.bounds.size.width / self.map.visibleMapRect.size.width);
                // Find out the line width at this zoom scale and outset the updateRect by that amount
                CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                // Ask the overlay view to update just the changed area.
                [self.pathRenderer setNeedsDisplayInMapRect:updateRect];
                currLocation = newLocation;
                // Speed
                self.currSpeedTxt.text = [NSString stringWithFormat:@"Speed: %.2f km/h", newLocation.speed];
                // TO-DO: save data to tmp files
            }
            //debug
            NSArray *fields = [self.recordManager readRecord];
            NSLog(@"read %lu: %@", [fields count], fields);
        }
    //}
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
    if (!self.pathRenderer)
    {
        _pathRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        self.pathRenderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.65];
        self.pathRenderer.lineWidth = 6;
    }
    return self.pathRenderer;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
@end
