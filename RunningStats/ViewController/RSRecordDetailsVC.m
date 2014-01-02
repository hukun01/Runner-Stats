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

// Numerics
CGFloat const kJBLineChartViewControllerChartHeight = 250.0f;
CGFloat const kJBLineChartViewControllerChartHeaderHeight = 75.0f;
CGFloat const kJBLineChartViewControllerChartHeaderPadding = 20.0f;
CGFloat const kJBLineChartViewControllerChartFooterHeight = 20.0f;

@interface RSRecordDetailsVC ()
@property (strong, nonatomic) RSRecordManager *recordManager;
//@property (strong, nonatomic) PNLineChart *lineChart;
@property (strong, nonatomic) JBLineChartView *lineChart;
//@property (strong, nonatomic) IBOutlet JBLineChartView *lineChart;
@property (strong, nonatomic) JBChartInformationView *informationView;
@property (strong, nonatomic) NSString *record;
@property (strong, nonatomic) NSArray *recordData;
// flagPoint is for marking every kilometer or mile covered
@property (assign, nonatomic) NSUInteger flagPoint;
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
    
    if ([self.recordData count] <= 1) {
        return;
    }
    
    self.lineChart = [[JBLineChartView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, 50, self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartHeight)];//[[JBLineChartView alloc] initWithFrame:CGRectMake(0, 55.0, SCREEN_WIDTH, 200.0)];
    self.lineChart.delegate = self;
    self.lineChart.dataSource = self;
    //headerView
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = [self getHeaderTitleFromRecord:self.record];
    headerView.titleLabel.textColor = kJBColorLineChartHeader;
    headerView.titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.titleLabel.shadowOffset = CGSizeMake(0, 1);
    headerView.subtitleLabel.text = [self getHeaderSubTitleFromRecord:self.record];
    headerView.subtitleLabel.textColor = kJBColorLineChartHeader;
    headerView.subtitleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.subtitleLabel.shadowOffset = CGSizeMake(0, 1);
    headerView.separatorColor = kJBColorLineChartHeaderSeparatorColor;
    self.lineChart.headerView = headerView;
    //footerView
    JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBLineChartViewControllerChartFooterHeight)];
    footerView.leftLabel.text = [NSString stringWithFormat:@"%d", 0];
    footerView.leftLabel.textColor = [UIColor blackColor];
    footerView.rightLabel.text = [[[self.recordData lastObject] objectAtIndex:1] description];
    footerView.rightLabel.textColor = [UIColor blackColor];
    footerView.sectionCount = [self.recordData count];
    footerView.footerSeparatorColor = [UIColor blackColor];
    self.lineChart.footerView = footerView;
    
    [self.view addSubview:self.lineChart];
    // informationView
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.lineChart.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.lineChart.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame)) layout:JBChartInformationViewLayoutVertical];
    [self.informationView setValueAndUnitTextColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    [self.informationView setTitleTextColor:[UIColor blackColor]];
    [self.informationView setValueAndUnitTextColor:PNTwitterColor];
    [self.informationView setTextShadowColor:nil];
    [self.informationView setSeparatorColor:[UIColor blackColor]];
    [self.view addSubview:self.informationView];
    
    [self.lineChart reloadData];
}

- (NSString *)getHeaderTitleFromRecord:(NSString *)record
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:record];
    [df setDateFormat:@"yyyy-MM-dd"];
    return [df stringFromDate:date];
}

- (NSString *)getHeaderSubTitleFromRecord:(NSString *)record
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:record];
    [df setDateFormat:@"HH:mm:ss"];
    return [df stringFromDate:date];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.lineChart setState:JBChartViewStateCollapsed];
    
    RSStatsVC *parentVC = (RSStatsVC *)self.navigationController.parentViewController;
    parentVC.pageControl.hidden = YES;
    parentVC.currentStatsView.scrollEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.lineChart setState:JBChartViewStateExpanded animated:YES];
}

- (void)showRecordFromName:(NSString *)filename
{
    self.record = filename;
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *recordPath = [docsPath stringByAppendingPathComponent:[[self getHeaderTitleFromRecord:filename] stringByAppendingString:@".csv"]];
    // TO-DO: Read record content from path
    self.recordData = [self.recordManager readRecordDetailsByPath:recordPath];
    if ([self.recordData count] <= 1) {
        NSLog(@"!? path:%@, filename:%@", recordPath, filename);
        
        return;
    }
    NSRange range = {0, [self.recordData count]-1};
    self.recordData = [self.recordData subarrayWithRange:range];
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
    [self.informationView setValueText:[NSString stringWithFormat:@"%.2f", [valueNumber doubleValue]] unitText:@"km/h"];
    [self.informationView setTitleText:[NSString stringWithFormat:@"%.2f", [[row objectAtIndex:1] doubleValue]]];
    [self.informationView setHidden:NO animated:YES];
}

- (void)lineChartView:(JBLineChartView *)lineChartView didUnselectChartAtIndex:(NSInteger)index
{
    [self.informationView setHidden:YES animated:YES];
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
