//
//  RSFirstViewController.m
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRunningVC.h"
#import "RSPath.h"

@interface RSRunningVC ()
@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UITextField *currSpeedTxt;
@property (strong, nonatomic) IBOutlet UITextField *distanceTxt;
@property (strong, nonatomic) IBOutlet UITextField *avgSpeedTxt;

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
    // map
    self.map.userTrackingMode = YES;
    
    self.map.showsUserLocation = YES;
    self.map.delegate = self;
    // locationManager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];

    //需要防抖动
    currLocation = [self.locationManager location];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    if (!self.path) {
        _path = [[RSPath alloc] initWithCenterCoordinate:currLocation.coordinate];
        [self.map addOverlay:self.path];
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currLocation.coordinate, 1000, 1000);
        [self.map setRegion:region animated:YES];
    }
    else {
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
                
                // Speed
                self.currSpeedTxt.text = [NSString stringWithFormat:@"Speed: %.2f km/h", newLocation.speed];
            }
        }
    }
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
