//
//  RSFirstViewController.m
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRunningVC.h"
#import "RSStatsFirstVC.h"
#import "RSStatsSecondVC.h"
#import "RSAnnotation.h"

#define DISCARD_ALERT_TAG 0
#define SAVE_ALERT_TAG 1
#define LOGIN_ALERT_TAG 2

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
@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;
@property (strong, nonatomic) NSString *cdString;
// before start, count down related
@property (strong, nonatomic) AVSpeechSynthesizer *speaker;
@property (assign, nonatomic) BOOL voiceOn;
// Unit labels
@property (strong, nonatomic) IBOutlet UILabel *distanceUnitLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedUnitLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedUnitLabel2;
// iAD banner
//@property (strong, nonatomic) ADBannerView *iAd;

@end

@implementation RSRunningVC
// add 1 after every feedback
static int distanceBound = 1;
// number of seconds
static int durationBound = 0;
// Denote wheter the record file has changed
static bool saveNewRecord;
// flag for resuming background music
static bool resumeMusic;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setUp];
    }
    return self;
}

+ (void)changeRecordStateTo:(BOOL)state
{
    saveNewRecord = state;
    // Reset the update state in other VCs
    if (state) {
        [RSStatsFirstVC changeUpdateStateTo:NO];
        [RSStatsSecondVC changeUpdateStateTo:NO];
    }
}

+ (BOOL)updateState
{
    return saveNewRecord;
}

- (void)setUp
{
    [RSRunningVC changeRecordStateTo:NO];
    _locationManager                 = [[CLLocationManager alloc] init];
    _locationManager.delegate        = self;
    _locationManager.distanceFilter  = 3.0;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _recordManager                   = [[RSRecordManager alloc] init];
    _isRunning                       = NO;
    _map.showsUserLocation           = YES;
    // reset data
    [self resetData];
    
    if (![_recordManager createCatalog]) {
        NSLog(@"Create record.csv failed.");
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.map.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(renewMapRegion)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    self.myNavigationItem.title = NSLocalizedString(@"FirstNavigationBarTitle", nil);
    [self setupADBannerWith:@"ca-app-pub-3727162321470301/2978487079"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self restoreUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.currLocation = [self.locationManager location];
    
    self.voiceOn = RS_VOICE_ON;
    [self updateUnitLabels];
    self.myNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Rank" style:UIBarButtonItemStylePlain target:self action:@selector(showGameCenter)];
}

- (void)showGameCenter
{
    if ([[RSGameKitHelper sharedGameKitHelper] gameCenterFeaturesEnabled] ) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:FLAG_HAS_SUBMITTED_SOCRE]) {
            RSRecordManager *recordManager = [[RSRecordManager alloc] init];
            NSArray *records = [recordManager readCatalog];
            double_t wholeMeters = 0.0;
            if ([records count] > 0) {
                for (NSArray *record in records) {
                    wholeMeters += [[record objectAtIndex:1] doubleValue];
                }
                wholeMeters /= 1000.0;
            }
            [[RSGameKitHelper sharedGameKitHelper] submitScore:wholeMeters category:LEADERBOARD_ID];
            [defaults setBool:YES forKey:FLAG_HAS_SUBMITTED_SOCRE];
            [defaults synchronize];
        }
        
        GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
        if (gameCenterController != nil) {
            gameCenterController.gameCenterDelegate = [RSGameKitHelper sharedGameKitHelper];
            gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
            gameCenterController.leaderboardIdentifier = LEADERBOARD_ID;
            [self presentViewController:gameCenterController animated:YES completion:nil];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:nil
                              message:NSLocalizedString(@"Login to game center", nil)
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"CancelOption", nil)
                              otherButtonTitles:NSLocalizedString(@"LoginOption", nil), nil];
        alert.tag = LOGIN_ALERT_TAG;
        [alert show];
    }
}

- (void)updateUnitLabels
{
    self.distanceUnitLabel.text = RS_DISTANCE_UNIT_STRING;
    self.speedUnitLabel.text    = RS_SPEED_UNIT_SHORT_STRING;
    self.speedUnitLabel2.text   = self.speedUnitLabel.text;
}

#pragma mark - Audio
- (BOOL)isHeadsetPluggedIn
{
    NSArray *availableOutputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    for (AVAudioSessionPortDescription *portDescription in availableOutputs) {
        if ([portDescription.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)configureAVAudioSession
{
    if (!self.speaker) {
        self.speaker = [[AVSpeechSynthesizer alloc] init];
        self.speaker.delegate = self;
    }
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    resumeMusic = session.otherAudioPlaying;
    //error handling
    BOOL success;
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    //set the audioSession override
    if ([self isHeadsetPluggedIn]) {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:NULL];
    }
    else {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:NULL];
    }
    //activate the audio session
    success = [session setActive:YES error:NULL];
    
    return success;
}

- (void)speakCountDown
{
    self.cdString = [self countDownString];
    if ([self.cdString isEqualToString:@""]) {
        NSLog(@"NULL String");
        return;
    }
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:self.cdString];
    utterance.rate = AVSpeechUtteranceMinimumSpeechRate;
    if (self.speaker && utterance) {
        [utterance setPitchMultiplier:1.25];
        [self.speaker speakUtterance:utterance];
    }
}

- (NSString *)countDownString
{
    int countDown = RS_COUNT_DOWN;
    NSString *result = @"";
    for (; countDown > 0; --countDown) {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%d, ", countDown]];
    }
    result = [result stringByAppendingString:NSLocalizedString(@"StartRunningText", nil)];
    return result;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    // If the speaker is counting down, when it finishes, start the running state
    if ([self.cdString isEqualToString:[utterance speechString]]) {
        self.isRunning = YES;
        [self startTimer];
    }
    if (resumeMusic) {
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
    }
}

# pragma mark - Start Session
- (IBAction)startSession:(id)sender
{
    [self.locationManager startUpdatingLocation];
    if (self.voiceOn && RS_COUNT_DOWN != 0 && [self configureAVAudioSession]) {
        [self speakCountDown];
    }
    else {
        [self startTimer];
        self.isRunning = YES;
        if (resumeMusic) {
            [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
        }
    }
    
    // Clear the data of last event
    [self.map removeOverlays:self.map.overlays];
    [self removeAllPinsButUserLocation];
    [self.path clearContents];
    [self resetData];
    
    self.startDate = [NSDate date];
    [self renewMapRegion];
    
    // Change accessibility of some UI elements and display iAd
    self.startButton.hidden             = YES;
    self.saveButton.hidden              = NO;
    self.stopButton.hidden              = NO;
    self.map.zoomEnabled                = NO;
    self.tabBarController.tabBar.hidden = YES;
    //self.iAd.hidden = NO;
    self.bannerView.hidden              = NO;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    if (!self.isRunning) {
        self.currLocation = newLocation;
        return;
    }
    if (!self.path) {
        self.path = [[RSPath alloc] init];
    }
    if (self.path.pointCount == 0) {
        self.currLocation = newLocation;
        if ([self.path saveFirstLocation:self.currLocation]) {
            [self.map addOverlay:self.path];
        }
    }
    
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
        self.distance = self.path.distance / RS_UNIT;
        if (self.distance > distanceBound) {
            // add annotation
            RSAnnotation *myAnn = [[RSAnnotation alloc] initWithTitle:[NSString stringWithFormat:@"%d", distanceBound] andLocation:[self.currLocation coordinate]];
            [self.map addAnnotation:myAnn];
            
            [self triggleVoiceFeedback];
            
            // reset data for every unit
            ++distanceBound;
            durationBound = 0;
        }
        self.speed = (SECONDS_OF_HOUR/RS_UNIT) * self.path.instantSpeed;
        // Move map with user location
        self.currLocation = newLocation;
    }
    // if the distance is small, also display speed if it is valid, but do not store it
    else if ([self.path isValidLocation:newLocation]) {
        self.speed = (SECONDS_OF_HOUR/RS_UNIT) * newLocation.speed;
    }
    
    NSTimeInterval duration = ABS([self.startDate timeIntervalSinceNow]);
    self.avgSpeed = (SECONDS_OF_HOUR/RS_UNIT) * self.path.distance / duration;
}

// Speak the current distance and the duration for the last km or mile
- (void)triggleVoiceFeedback
{
    if (!self.voiceOn) {
        return;
    }
    NSString *distanceText = [[NSString stringWithFormat:NSLocalizedString(@"DistanceCovered", nil), distanceBound] stringByAppendingString:RS_UNIT_VOICE];
    NSString *durationString = [[NSString alloc] init];
    if (durationBound < SECONDS_OF_HOUR) {
        durationString = [self timeFormatted:durationBound longerThanOneHour:NO];
    }
    else {
        durationString = [self timeFormatted:durationBound longerThanOneHour:YES];
    }
    NSString *durationText = [NSLocalizedString(@"DurationText", nil) stringByAppendingString:durationString];
    NSString *feedBackString = [distanceText stringByAppendingString:durationText];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:feedBackString];
    utterance.rate = (AVSpeechUtteranceDefaultSpeechRate + AVSpeechUtteranceMinimumSpeechRate)/2;
    if ([self configureAVAudioSession] && self.speaker && utterance) {
        [utterance setPitchMultiplier:1.25];
        [self.speaker speakUtterance:utterance];
    }
}

- (NSString *)timeFormatted:(int)totalSeconds
          longerThanOneHour:(BOOL)islonger
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    if (!islonger) {
        if (seconds == 0) {
            return [NSString stringWithFormat:NSLocalizedString(@"minutes", nil), minutes];
        }
        return [NSString stringWithFormat:NSLocalizedString(@"minSec", nil), minutes, seconds];
    }
    else {
        if (seconds == 0) {
            return [NSString stringWithFormat:NSLocalizedString(@"hourMin", nil), hours, minutes];
        }
        return [NSString stringWithFormat:NSLocalizedString(@"hourMinSec", nil), hours, minutes, seconds];
    }
}

#pragma mark - Discard and Save Session
- (IBAction)discardSession:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"DiscardTitle", nil)
                          message:NSLocalizedString(@"Do you want to Discard", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"CancelOption", nil)
                          otherButtonTitles:NSLocalizedString(@"DiscardOption", nil), nil];
    alert.tag = DISCARD_ALERT_TAG;
    [alert show];
}

- (IBAction)saveSession:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"SaveTitle", nil)
                          message:NSLocalizedString(@"Do you want to Save", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"CancelOption", nil)
                          otherButtonTitles:NSLocalizedString(@"SaveOption", nil), nil];
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
            // Remove overlay, clear path
            [self.map removeOverlays:[self.map overlays]];
            [self.path clearContents];
            [self resetData];
            [self removeAllPinsButUserLocation];
        }
        // Save session
        else if (alertView.tag == SAVE_ALERT_TAG) {
            [self saveSessionAsRecord];
        }
        // Login to game center
        else if (alertView.tag == LOGIN_ALERT_TAG) {
            [[RSGameKitHelper sharedGameKitHelper] authenticateLocalPlayer];
        }
    }
}

- (void)stopSession
{
    self.isRunning = NO;
    [self.locationManager stopUpdatingLocation];
    [self stopTimer];
    [self restoreUI];
    // When stop speaking, make the cdString empty
    // for the check in the following didFinishSpeechUtterance method
    self.cdString = @"";
    if (self.speaker.isSpeaking) {
        [self.speaker stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    if (resumeMusic) {
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:NULL];
    }
}

- (void)resetData
{
    self.speed = 0.0;
    self.distance = 0.0;
    self.avgSpeed = 0.0;
    self.sessionSeconds = 0;
    durationBound = 0;
    distanceBound = 1;
}
// restore main part of UI, keep path and annotations
- (void)restoreUI
{
    // Restore buttons
    self.startButton.hidden = NO;
    self.stopButton.hidden = YES;
    self.saveButton.hidden = YES;
    self.tabBarController.tabBar.hidden = NO;
    self.map.zoomEnabled = YES;
    //self.iAd.hidden = YES;
    self.bannerView.hidden = YES;
}

- (void)stopTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)startTimer
{
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    }
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

// In record, the measure unit of distance is meters,
// the unit of speed is meters/seconds
- (void)saveSessionAsRecord
{
    if (0 == [self.path.runningData count]) {
        return;
    }
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateformatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSTimeInterval duration = ABS([self.startDate timeIntervalSinceNow]);
    NSString *durStr = [NSString stringWithFormat:@"%d", (int)duration];
    NSString *startDateString = [dateformatter stringFromDate:self.startDate];
    CLLocationDistance finalDistance = self.path.distance;
    NSString *disStr;
    if (finalDistance > 10.0) {
        disStr = [NSString stringWithFormat:@"%.1f",finalDistance];
    }
    else {
        disStr = [NSString stringWithFormat:@"%.2f",finalDistance];
    }
    NSString *avgSpdStr = [NSString stringWithFormat:@"%.2f",self.path.distance / duration];
    
    NSArray *newRecord = @[startDateString, disStr, durStr, avgSpdStr];
    [self.recordManager addCatalogEntry:newRecord];
    
    
    [self.path saveTmpDataAsRecord];
    // Set the flag that denotes the other VC needs to re-display animation of figures
    [RSRunningVC changeRecordStateTo:YES];

    // Set the flag of game center to remember that the latest result has not been submitted
    if ([[RSGameKitHelper sharedGameKitHelper] gameCenterFeaturesEnabled]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:FLAG_HAS_SUBMITTED_SOCRE];
        [defaults synchronize];
    }
}

#pragma mark - ADBanner configuration
//static bool bannerHasBeenLoaded = NO;
- (void)setupADBannerWith:(NSString *)adUintID
{
    if (!self.bannerView) {
        self.bannerView                    = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.bannerView.adUnitID           = adUintID;
        self.bannerView.rootViewController = self;
        CGRect adFrame                     = self.bannerView.frame;
        adFrame.origin.y                   = self.view.frame.size.height - 50;
        self.bannerView.frame              = adFrame;
        [self.view addSubview:self.bannerView];
    }
    
    GADRequest *request = [GADRequest request];
    
    GADAdMobExtras *extras = [[GADAdMobExtras alloc] init];
    extras.additionalParameters =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @"FFFFFF", @"color_bg",
     @"FFFFFF", @"color_bg_top",
     @"FFFFFF", @"color_border",
     @"000080", @"color_link",
     @"808080", @"color_text",
     @"008000", @"color_url",
     nil];
    
    [request registerAdNetworkExtras:extras];
//    
//    request.testDevices = @[GAD_SIMULATOR_ID];
//    request.testing = YES;
    
    [self.bannerView loadRequest:request];
}
//- (void)setupADBanner
//{
//    if (!self.iAd) {
//        self.iAd = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
//        self.iAd.hidden = YES;
//        CGRect iAdFrame = self.iAd.frame;
//        iAdFrame.origin.y = self.view.frame.size.height-50;
//        self.iAd.frame = iAdFrame;
//        self.iAd.delegate = self;
//        [self.view addSubview:self.iAd];
//    }
//}

//#pragma mark - ADBanner delegate
//- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
//{
//    if (!self.isRunning) {
//        return;
//    }
//    if (!bannerHasBeenLoaded) {
//        NSLog(@"Some error about ads: %@", error);
//        self.iAd.hidden = YES;
//    }
//}

//- (void)bannerViewActionDidFinish:(ADBannerView *)banner
//{
//    NSLog(@"bannerview was selected");
//}
//
//- (void)bannerViewDidLoadAd:(ADBannerView *)banner
//{
//    NSLog(@"Success!");
//    bannerHasBeenLoaded = YES;
//    if (self.isRunning) {
//        self.iAd.hidden = NO;
//    }
//}

//- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
//{
//    return YES;
//}

#pragma mark - Utility functions
#pragma mark - About map

- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.isRunning) {
        self.map.centerCoordinate = userLocation.location.coordinate;
    }
    if (![RSRunningVC updateState]) {
        [self renewMapRegion];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RSAnnotation class]]) {
        return [(RSAnnotation *)annotation annotationView];
    }
    else {
        return nil;
    }
}

- (void)renewMapRegion
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.map.userLocation.coordinate, MAP_REGION_SIZE, MAP_REGION_SIZE);
    [self.map setRegion:region animated:YES];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
    if (!self.pathRenderer) {
        self.pathRenderer             = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        self.pathRenderer.strokeColor = [[UIColor alloc] initWithRed:66.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:0.75];
        self.pathRenderer.lineWidth   = 6.5;
    }
    return self.pathRenderer;
}

- (void)removeAllPinsButUserLocation
{
    id userLocation = self.map.userLocation;
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:self.map.annotations];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [self.map removeAnnotations:pins];
}

#pragma mark - About labels
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
    _sessionSeconds      = sessionSeconds;
    self.timerLabel.text = [self.recordManager timeFormatted:(int)sessionSeconds withOption:FORMAT_HHMMSS];
}

- (void)timerTick
{
    self.sessionSeconds += 1;
    durationBound       += 1;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
@end
