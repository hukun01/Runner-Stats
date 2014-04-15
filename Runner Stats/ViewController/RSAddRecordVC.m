//
//  RSAddRecordVC.m
//  Runner Stats
//
//  Created by Mr. Who on 4/10/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSAddRecordVC.h"
#import "RSRecordManager.h"
#import "CHCSVParser.h"

@interface RSAddRecordVC ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBtn;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (strong, nonatomic) IBOutlet UIDatePicker *recordDatePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (strong, nonatomic) IBOutlet UIPickerView *distancePicker;

@property (strong, nonatomic) NSMutableArray *distanceItems;

@end

@implementation RSAddRecordVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _distanceItems = [NSMutableArray array];
        for (int i=1; i < 101; ++i) {
            [_distanceItems addObject:[NSString stringWithFormat:@"%.1lf", (double)i * 0.5]];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.saveBtn.title = NSLocalizedString(@"SaveOption", nil);
    self.cancelBtn.title = NSLocalizedString(@"CancelOption", nil);
    
    [self.recordDatePicker setMaximumDate:[NSDate date]];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents * components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger minutes = [defaults integerForKey:@"countDownDuration"];
    [components setHour:0];
    if (minutes != 0) {
        [components setMinute:minutes];
    }
    else {
        [components setMinute:30];
    }
    [components setSecond:0];
    NSDate * date = [cal dateFromComponents:components];
    [self.timePicker setDate:date animated:TRUE];
    
    self.distancePicker.dataSource = self;
    self.distancePicker.delegate = self;
    NSInteger distanceRow = [defaults integerForKey:@"distanceRow"];
    if (distanceRow != 0) {
        [self.distancePicker selectRow:distanceRow inComponent:0 animated:YES];
    }
    else {
        [self.distancePicker selectRow:9 inComponent:0 animated:YES];
    }
    
    [self setupADBannerWith:@"ca-app-pub-3727162321470301/7792829476"];
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return self.distanceItems[row];
    }
    else {
        return RS_DISTANCE_UNIT_STRING;
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (component == 0) {
        return [self.distanceItems count];
    }
    else {
        return 1;
    }
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender
{
    // get record name, which is the date
    NSDate *date = self.recordDatePicker.date;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    // get duration
    NSTimeInterval duration = self.timePicker.countDownDuration;
    // get distance
    double distance = [self.distanceItems[[self.distancePicker selectedRowInComponent:0]] doubleValue] * RS_UNIT;
    
    // add catalog entry
    [RSRecordManager addCatalogEntry:@[[df stringFromDate:date],
                                       [NSString stringWithFormat:@"%lf", distance],
                                       [NSString stringWithFormat:@"%lf", duration],
                                       [NSString stringWithFormat:@"%lf", distance / duration]]];
    
    // add record file
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    df.dateFormat = @"yyyy-MM-dd";
    NSString *recordName = [docsPath stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@.csv", [df stringFromDate:date]]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:recordName]) {
        if(![[NSFileManager defaultManager] removeItemAtPath:recordName error:NULL])
            NSLog(@"Remove duplicate file failed.");
        else
            NSLog(@"Remove duplicate file.");
    }
    
    if (![[NSFileManager defaultManager] createFileAtPath:recordName contents:nil attributes:nil])
    {
        NSLog(@"Record creation failed.");
    }
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:recordName];
    NSMutableArray *simulatedData = [NSMutableArray array];
    [simulatedData addObject:@[@"0.0",
                               @"0.0",
                               [NSString stringWithFormat:@"%lf", distance / duration]]];
    
    [simulatedData addObject:@[[NSString stringWithFormat:@"%lf", duration],
                               [NSString stringWithFormat:@"%lf", distance],
                               [NSString stringWithFormat:@"%lf", distance / duration]]];
    
    for (NSArray *line in simulatedData) {
        [writer writeLineOfFields:line];
    }
    
    // save current config for future use
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.timePicker.countDownDuration/60 forKey:@"countDownDuration"];
    [defaults setInteger:[self.distancePicker selectedRowInComponent:0] forKey:@"distanceRow"];
    [defaults synchronize];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)setupADBannerWith:(NSString *)adUintID
{
    if (!self.bannerView) {
        self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.bannerView.adUnitID = adUintID;
        self.bannerView.rootViewController = self;
        CGRect adFrame = self.bannerView.frame;
        adFrame.origin.y = self.view.frame.size.height - 50;
        self.bannerView.frame = adFrame;
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
    
    //    request.testDevices = @[GAD_SIMULATOR_ID];
    //    request.testing = YES;
    
    [self.bannerView loadRequest:request];
}

@end
