//
//  RSStatsSecondVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/30/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSStatsSecondVC.h"
#import "PNChart.h"
#import "TEAContributionGraph.h"
#import "RSRecordManager.h"
#import "RSRunningVC.h"

#define TEACHART_WIDTH 190
#define TEACHART_HEIGHT 162

@interface RSStatsSecondVC ()
@property (strong, nonatomic) PNBarChart *barChart;
@property (strong, nonatomic) TEAContributionGraph *contributionGraph;
@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;
@property (strong, nonatomic) RSRecordManager *recordManager;
@property (strong, nonatomic) NSArray *records;

@property (strong, nonatomic) ADBannerView *iAd;
@end

@implementation RSStatsSecondVC
// Denote wheter the record file has changed
static bool updateNewRecord;

+ (void)changeUpdateStateTo:(BOOL)state
{
    updateNewRecord = state;
}

+ (BOOL)updateState
{
    return updateNewRecord;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _recordManager = [[RSRecordManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [RSStatsSecondVC changeUpdateStateTo:NO];
    self.myNavigationItem.title = NSLocalizedString(@"Running Frequency", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup data
    if (!self.records || ([RSRunningVC updateState] && ![RSStatsSecondVC updateState])) {
        self.records = [self.recordManager readRecord];
        [RSStatsSecondVC changeUpdateStateTo:YES];
    }
    
    [self setupContributionGraph];
    [self setupBarChart];
    // setup iAd banner
    [self setupADBanner];
    [self.barChart strokeChart];
    [self.view addSubview:self.barChart];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - contribution graph
- (void)setupContributionGraph
{
    self.contributionGraph = [[TEAContributionGraph alloc] initWithFrame:CGRectMake(65, 55, TEACHART_WIDTH, TEACHART_HEIGHT)];
    self.contributionGraph.backgroundColor = [UIColor whiteColor];
    self.contributionGraph.width = 22;
    self.contributionGraph.spacing = 6;
    
    [self setupContributionGraphData];
    [self.view addSubview:self.contributionGraph];
}

- (void)setupContributionGraphData
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *recentRecords = [self readCurrentMonthRecord];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *todayString = [df stringFromDate:[NSDate date]];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger prevDays = 0;
    NSInteger days = 0;
    for (NSArray *row in recentRecords) {
        NSString *dateString1 = [row firstObject];
        if ([self date:dateString1 isInSameMonthWithDate:todayString]) {
            NSDate *recordDate = [df dateFromString:dateString1];
            days = [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:recordDate];
            // Fill the result array with 0(no-record date) and 1(record date)
            for (int i=0; i < days-prevDays-1; ++i) {
                [result addObject:@0];
            }
            [result addObject:@1];
            prevDays = days;
        }
    }
    // Change today's rect to green color
    NSArray *lastRow = [recentRecords lastObject];
    NSString *recordDateOfLastRow = [lastRow firstObject];
    NSDate *lastDate = [df dateFromString:recordDateOfLastRow];
    df.dateFormat = @"yyyy-MM-dd";
    NSString *lastString = [df stringFromDate:lastDate];
    todayString = [df stringFromDate:[NSDate date]];
    if ([lastString isEqualToString:todayString]) {
        [result replaceObjectAtIndex:[result count]-1 withObject:@5];
    }
    else {
        [result addObject:@5];
    }
    
    self.contributionGraph.data = result;
}

- (BOOL)date:(NSString *)dateString1 isInSameMonthWithDate:(NSString *)dateString2
{
    // Convert both date string into yyyy-MM
    NSString *string1 = [self.recordManager subStringFromDateString:dateString1];
    NSString *string2 = [self.recordManager subStringFromDateString:dateString2];
    
    return [string1 isEqualToString:string2];
}

// Return the array of records of current month
- (NSArray *)readCurrentMonthRecord
{
    NSInteger recordsNumber = [self.records count];
    if (recordsNumber < 1) {
        return [NSArray array];
    }
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger daysOfMonth = [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:today];
    if (recordsNumber > daysOfMonth) {
        NSInteger location =  recordsNumber - daysOfMonth;
        NSInteger length = daysOfMonth;
        NSRange range = {location, length};
        return [self.records subarrayWithRange:range];
    }
    else {
        return self.records;
    }
}

#pragma mark - bar chart
- (void)setupBarChart
{
    self.barChart = [[PNBarChart alloc] initWithFrame:CGRectMake(0, 220, SCREEN_WIDTH, 200.0)];
    // barChart UI
    UIColor *myGray = [[UIColor alloc] initWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
    self.barChart.barBackgroundColor = myGray;
    self.barChart.strokeColor = PNTwitterColor;
    // add title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.barChart.frame.size.width, 30)];
    titleLabel.text = NSLocalizedString(@"barChartTitle", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor colorWithWhite:0.56 alpha:1];
    titleLabel.font = [UIFont systemFontOfSize:14];
    [self.barChart addSubview:titleLabel];
    // barChart data
    [self setupBarChartData];
}

// Calculate the recent 7 weeks
#define BIGGEST_NUM_OF_RECORDS 49
- (void)setupBarChartData
{
    NSArray *data = [[NSArray alloc] init];
    NSInteger recordAmount = [self.records count];
    if (recordAmount > BIGGEST_NUM_OF_RECORDS) {
        NSInteger location = recordAmount - BIGGEST_NUM_OF_RECORDS;
        NSInteger length = BIGGEST_NUM_OF_RECORDS;
        NSRange range = {location, length};
        data = [self.records subarrayWithRange:range];
    }
    else {
        data = self.records;
    }
    if ([data count] < 1) {
        return;
    }
    NSMutableArray *xLabelsArray = [[NSMutableArray alloc] initWithArray:@[@"00:00", @"00:00", @"00:00", @"00:00", @"00:00", @"00:00", @"00:00"]];
    NSMutableArray *yValuesArray = [[NSMutableArray alloc] initWithArray:@[@0, @0, @0, @0, @0, @0, @0]];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone localTimeZone];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSInteger indexOfPoint = [xLabelsArray count]-1;
    NSInteger indexOfRecord = [data count]-1;
    NSDate *currentWeekDate = [self getToday];
    NSDate *firstDateOfWeek = [self getFirstDayOfTheWeekFromDate:currentWeekDate];
    NSUInteger durationSeconds = 0;
    // Compare recordDate and first date of the last N week,
    // if they are in the same week, add the duration,
    // or write to points array, and go to the further previous week.
    while (indexOfPoint >= 0 && indexOfRecord >= 0) {
        NSArray *row = [data objectAtIndex:indexOfRecord];
        NSDate *recordDate = [df dateFromString:[row firstObject]];
        if ([self inSameWeekBetweenDate:firstDateOfWeek andDate:recordDate]) {
            durationSeconds += [[row objectAtIndex:2] integerValue];
            -- indexOfRecord;
        }
        else {
            [xLabelsArray replaceObjectAtIndex:indexOfPoint withObject:[self.recordManager timeFormatted:(int)durationSeconds withOption:FORMAT_HHMM]];
            //NSLog(@"P %ld, R %ld, %@",(long)indexOfPoint,(long)indexOfRecord, [self.recordManager timeFormatted:(int)durationSeconds withOption:FORMAT_HHMM]);
            [yValuesArray replaceObjectAtIndex:indexOfPoint withObject:[NSNumber numberWithInteger:durationSeconds]];
            -- indexOfPoint;
            durationSeconds = 0;
            firstDateOfWeek = [self minusAWeekFromDate:firstDateOfWeek];
        }
    }
    // Add the last point if available
    if (indexOfPoint >= 0) {
        [xLabelsArray replaceObjectAtIndex:indexOfPoint withObject:[self.recordManager timeFormatted:(int)durationSeconds withOption:FORMAT_HHMM]];
        [yValuesArray replaceObjectAtIndex:indexOfPoint withObject:[NSNumber numberWithInteger:durationSeconds]];
    }
    
    self.barChart.xLabels = xLabelsArray;
    self.barChart.yValues = yValuesArray;
}

- (NSDate *)getToday
{
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    return destinationDate;
}
    
#define SECONDS_OF_WEEK 604800
- (BOOL)inSameWeekBetweenDate:(NSDate *)oldDate andDate:(NSDate *)newDate
{
    NSTimeInterval interval = [newDate timeIntervalSinceDate:oldDate];
    if (interval < 0 || interval > SECONDS_OF_WEEK) {
        return NO;
    }
    return YES;
}

- (NSDate *)minusAWeekFromDate:(NSDate *)date
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = -7;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    date = [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
    return date;
}

// Finds the date for the first day of the week
- (NSDate *)getFirstDayOfTheWeekFromDate:(NSDate *)givenDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Edge case where beginning of week starts in the prior month
    NSDateComponents *edgeCase = [[NSDateComponents alloc] init];
    [edgeCase setMonth:2];
    [edgeCase setDay:1];
    // Get current year
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy";
    NSString *year = [df stringFromDate:givenDate];
    //NSLog(@"YYYYY  %@", year);
    [edgeCase setYear:[year integerValue]];
    NSDate *edgeCaseDate = [calendar dateFromComponents:edgeCase];
    
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:edgeCaseDate];
    [components setWeekday:1]; // 1 == Sunday, 7 == Saturday
    [components setWeek:[components week]];
    
    //NSLog(@"Edge case date is %@ and beginning of that week is %@", edgeCaseDate , [calendar dateFromComponents:components]);
    NSTimeInterval interval = [givenDate timeIntervalSinceDate:edgeCaseDate];
    if (interval <= 16*3600 && interval >= -8*3600) {
        return [calendar dateFromComponents:components];
    }
    
    // Find Sunday for the given date
    components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:givenDate];
    [components setWeekday:1]; // 1 == Sunday, 7 == Saturday
    [components setWeek:[components week]];
    
   // NSLog(@"Original date is %@ and beginning of week is %@", givenDate , [calendar dateFromComponents:components]);
    
    return [calendar dateFromComponents:components];
}

#pragma mark -iAd
static bool bannerHasBeenLoaded = NO;

- (void)setupADBanner
{
    if (!self.iAd) {
        self.iAd = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        self.iAd.hidden = YES;
        CGRect iAdFrame = self.iAd.frame;
        iAdFrame.origin.y = self.view.frame.size.height-50;
        self.iAd.frame = iAdFrame;
        self.iAd.delegate = self;
        [self.view addSubview:self.iAd];
    }
}

#pragma mark - ADBanner delegate
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    // When error happens, if the ad has been there, just keep it
    // otherwise, hide it.
    if (!bannerHasBeenLoaded) {
        self.iAd.hidden = YES;
    }
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    bannerHasBeenLoaded = YES;
    self.iAd.hidden = NO;
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

@end
