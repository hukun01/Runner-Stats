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

#define TEACHART_WIDTH 190
#define TEACHART_HEIGHT 162

@interface RSStatsSecondVC ()
@property (strong, nonatomic) PNBarChart *barChart;
@property (strong, nonatomic) TEAContributionGraph *contributionGraph;
@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;
@property (strong, nonatomic) RSRecordManager *recordManager;
@property (strong, nonatomic) NSArray *records;
@end

@implementation RSStatsSecondVC

static int onceAnimated = 2;

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
    
    self.myNavigationItem.title = NSLocalizedString(@"Running Frequency", nil);
    
    self.records = [self.recordManager readRecord];
    
    [self setupContributionGraph];
    [self setupBarChart];
}

- (void)setupContributionGraph
{
    self.contributionGraph = [[TEAContributionGraph alloc] initWithFrame:CGRectMake(65, 65, TEACHART_WIDTH, TEACHART_HEIGHT)];
    self.contributionGraph.backgroundColor = [UIColor whiteColor];
    self.contributionGraph.width = 22;
    self.contributionGraph.spacing = 6;
    self.contributionGraph.data = @[@0, @1, @0, @0, @0, @4, @0, @5, @0, @0, @0, @3, @0, @0, @0, @5, @0, @0, @6, @0, @0, @0, @3, @0, @3, @0, @4, @0, @5, @0, @0];
    [self.view addSubview:self.contributionGraph];
}

- (NSArray *)readLast30DaysRecord
{
    NSArray *array = [[NSArray alloc] init];
    NSInteger recordsNumber = [self.records count];
    if (recordsNumber < 1) {
        return array;
    }
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger days = [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:today];
    NSRange range = {recordsNumber > days ? (recordsNumber - days) : 0, recordsNumber};
    return [array subarrayWithRange:range];
}

- (void)setupBarChart
{
    self.barChart = [[PNBarChart alloc] initWithFrame:CGRectMake(0, 235.0, SCREEN_WIDTH, 200.0)];
    // barChart UI
    UIColor *myGray = [[UIColor alloc] initWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
    self.barChart.barBackgroundColor = myGray;
    self.barChart.strokeColor = PNTwitterColor;
    // barChart data
    self.barChart.xLabels = @[@"05:50", @"06:10", @"05:59", @"06:33", @"07:10", @"05:50",
                              @"06:10", @"06:33"];
    self.barChart.yValues = @[@3, @7, @1, @3, @5, @1,
                              @10, @2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (onceAnimated > 0) {
        --onceAnimated;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (0 == onceAnimated) {
        --onceAnimated;
        [self.barChart strokeChart];
        [self.view addSubview:self.barChart];
    }
}

@end
