//
//  RSRecordDetailsVC.m
//  RunningStats
//
//  Created by Mr. Who on 1/1/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSRecordDetailsVC.h"
#import "RSRecordManager.h"
#import "PNChart.h"
#import "JBChartInformationView.h"
#import "JBChartHeaderView.h"
#import "JBLineChartFooterView.h"
#import "RSStatsVC.h"

#define NUMBER_OF_XY_POINTS 60
#define NUMBER_OF_SECTION_POINTS 30

// Numerics
CGFloat const kJBLineChartViewControllerChartHeight = 300.0f;
CGFloat const kJBLineChartViewControllerChartHeaderHeight = 70.0f;
CGFloat const kJBLineChartViewControllerChartHeaderPadding = 10.0f;
CGFloat const kJBLineChartViewControllerChartFooterHeight = 20.0f;

@interface RSRecordDetailsVC ()
@property (strong, nonatomic) RSRecordManager *recordManager;
@property (strong, nonatomic) JBLineChartView *lineChart;
@property (strong, nonatomic) JBChartInformationView *infoView;
@property (strong, nonatomic) NSString *record;
@property (strong, nonatomic) NSString *recordPath;
@property (strong, nonatomic) NSArray *recordData;
// flagPoint is for marking every kilometer or mile covered
@property (assign, nonatomic) NSUInteger flagPoint;
@property (assign, nonatomic) CLLocationSpeed maxSpeed;
@end

@implementation RSRecordDetailsVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //_lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 235.0, SCREEN_WIDTH, 200.0)];
        _recordManager = [[RSRecordManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.flagPoint = 1000;
    [self configureDataSource];
    
    if ([self.recordData count] <= 1) {
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // lineChart
    [self configureLineChart];
    // headerView
    [self configureHeaderView];
    // footerView
    [self configureFooterView];
    // informationView
    [self configureInfoView];
    
    [self.view addSubview:self.lineChart];
    [self.lineChart reloadData];
    [self.lineChart setState:JBChartViewStateCollapsed];
    // Disable the former page view
    RSStatsVC *parentVC = (RSStatsVC *)self.navigationController.parentViewController;
    parentVC.pageControl.hidden = YES;
    parentVC.currentStatsView.scrollEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.lineChart setState:JBChartViewStateExpanded animated:YES];
}

- (void)configureDataSource
{
    NSArray *dataArray = [self.recordManager readRecordDetailsByPath:self.recordPath] ;
    if ([dataArray count] <= 1) {
        NSLog(@"!? path:%@", self.recordPath);
        return;
    }
    // allow at most 50 points to be drawn
    CLLocationDistance SMALLEST_GAP = [[[dataArray objectAtIndex:[dataArray count]-2] objectAtIndex:1] doubleValue] / NUMBER_OF_XY_POINTS;
    SMALLEST_GAP = MAX(SMALLEST_GAP, 30.0);
    
    NSMutableArray *tempRecordData = [[NSMutableArray alloc] init];
    CLLocationDistance distanceFilter = 0;
    CLLocationDistance currentDistance = 0;
    self.maxSpeed = 0;
    for (int i=0; i < [dataArray count]-1; ++i) {
        currentDistance = [[dataArray[i] objectAtIndex:1] doubleValue];
        if ((currentDistance - distanceFilter) > SMALLEST_GAP) {
            distanceFilter = currentDistance;
            [tempRecordData addObject:dataArray[i]];
            self.maxSpeed = MAX(self.maxSpeed, [[dataArray[i] lastObject] doubleValue]);
        }
    }
    // add the last line of data
    if ((currentDistance - distanceFilter) != 0) {
        [tempRecordData addObject:[dataArray objectAtIndex:[dataArray count]-2]];
    }
    self.recordData = [NSArray arrayWithArray:tempRecordData];
}

- (void)configureLineChart
{
    self.lineChart = [[JBLineChartView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, 50, self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartHeight)];
    self.lineChart.delegate = self;
    self.lineChart.dataSource = self;
}

- (void)configureHeaderView
{
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = [self getHeaderTitleFromRecord:self.record];
    headerView.titleLabel.textColor = kJBColorLineChartHeader;
    headerView.titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.titleLabel.shadowOffset = CGSizeMake(0, 1);
    //headerView.subtitleLabel.text = [self getHeaderSubTitleFromRecord:self.record];
    headerView.subtitleLabel.text = [NSString stringWithFormat:@"Max Speed: %.1f km/h", self.maxSpeed * 3.6];
    headerView.subtitleLabel.textColor = kJBColorLineChartHeader;
    headerView.subtitleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.subtitleLabel.shadowOffset = CGSizeMake(0, 1);
    headerView.separatorColor = kJBColorLineChartHeaderSeparatorColor;
    self.lineChart.headerView = headerView;
}

- (void)configureFooterView
{
    JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartFooterHeight)];
    footerView.leftLabel.text = [NSString stringWithFormat:@"%d", 0];
    footerView.leftLabel.textColor = [UIColor blackColor];
    CLLocationDistance distance = [[[self.recordData lastObject] objectAtIndex:1] doubleValue];
    footerView.rightLabel.text = [NSString stringWithFormat:@"%.2f km", distance/1000.0];
    footerView.rightLabel.textColor = [UIColor blackColor];
    footerView.sectionCount = NUMBER_OF_SECTION_POINTS;
    footerView.footerSeparatorColor = [UIColor blackColor];
    self.lineChart.footerView = footerView;
}

- (void)configureInfoView
{
    self.infoView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.lineChart.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.lineChart.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame)) layout:JBChartInformationViewLayoutVertical];
    [self.infoView setValueAndUnitTextColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    [self.infoView setTitleTextColor:[UIColor blackColor]];
    [self.infoView setValueAndUnitTextColor:PNTwitterColor];
    [self.infoView setTextShadowColor:nil];
    [self.infoView setSeparatorColor:[UIColor blackColor]];
    [self.view addSubview:self.infoView];
}

- (NSString *)getHeaderTitleFromRecord:(NSString *)record
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:record];
    [df setDateFormat:@"yyyy-MM-dd HH:mm"];
    return [df stringFromDate:date];
}

- (NSString *)getRecordNameFromRecordDate:(NSString *)record
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:record];
    [df setDateFormat:@"yyyy-MM-dd"];
    return [df stringFromDate:date];
}

- (void)showRecordFromDate:(NSString *)recordDate
{
    self.record = recordDate;
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    self.recordPath = [docsPath stringByAppendingPathComponent:[[self getRecordNameFromRecordDate:recordDate] stringByAppendingString:@".csv"]];
    //[self configureChartByRecordData:[recordData subarrayWithRange:range]];
    //[self.lineChart strokeChart];
    
    // TO-DO: Draw figures: lineChart and barChart
    // lineChart for duration-speed
    // barChart for pace
    // TO-DO: Use a dictionary to store {1 km : 06:00},{2 km : 06:15} ...
}

#pragma mark - JBLineChartViewDelegate

- (NSInteger)lineChartView:(JBLineChartView *)lineChartView heightForIndex:(NSInteger)index
{
    NSArray *row = [self.recordData objectAtIndex:index];
    return [[row lastObject] floatValue] * 3600; // y-position of poinnt at index (x-axis)
}

- (void)lineChartView:(JBLineChartView *)lineChartView didSelectChartAtIndex:(NSInteger)index
{
    NSArray *row = [self.recordData objectAtIndex:index];
    NSNumber *valueNumber = [NSNumber numberWithDouble:[[row lastObject] doubleValue] * 3.6 ];
    [self.infoView setValueText:[NSString stringWithFormat:@"%.2f", [valueNumber doubleValue]] unitText:@" km/h"];
    [self.infoView setTitleText:[NSString stringWithFormat:@"%.2f", [[row objectAtIndex:1] doubleValue]/1000] unitText:@" km"];
    [self.infoView setHidden:NO animated:YES];
}

- (void)lineChartView:(JBLineChartView *)lineChartView didUnselectChartAtIndex:(NSInteger)index
{
    [self.infoView setHidden:YES animated:YES];
}

#pragma mark - JBLineChartViewDataSource

- (NSInteger)numberOfPointsInLineChartView:(JBLineChartView *)lineChartView
{
    return [self.recordData count]; // number of points in chart
}

- (UIColor *)lineColorForLineChartView:(JBLineChartView *)lineChartView
{
    return PNTwitterColor;
}

- (UIColor *)selectionColorForLineChartView:(JBLineChartView *)lineChartView
{
    return PNTwitterColor;
}

//- (void)configureChartByRecordData:(NSArray *)recordData
//{
//    NSMutableArray *xLabels = [[NSMutableArray alloc] init];
//    NSMutableArray *speedArray = [[NSMutableArray alloc] init];
//    
//    CLLocationDistance distanceBound = 0.0;
//    for (NSArray *recordLine in recordData) {
//        CLLocationDistance currentDistance = [[recordLine objectAtIndex:1] doubleValue];
//        if (currentDistance - distanceBound > 30) {
//            [xLabels addObject:[NSString stringWithFormat:@"%.1f", currentDistance/1000]];
//            distanceBound = currentDistance;
//        }
//        CLLocationSpeed speed = [[recordLine lastObject] doubleValue];
//        speed *= 3.6;
//        [speedArray addObject:[NSString stringWithFormat:@"%.1f", speed]];
//    }
//    self.lineChart.xLabels = xLabels;
//    PNLineChartData *data = [PNLineChartData new];
//    data.color = PNTwitterColor;
//    data.itemCount = [xLabels count];
//    data.getData = ^(NSUInteger index) {
//        CGFloat yValue = [[speedArray objectAtIndex:index] floatValue];
//        return [PNLineChartDataItem dataItemWithY:yValue];
//    };
//    self.lineChart.chartData = @[data];
//}

@end
