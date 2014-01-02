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

@interface RSStatsSecondVC ()
@property (strong, nonatomic) PNBarChart *barChart;
@property (strong, nonatomic) TEAContributionGraph *contributionGraph;
@end

@implementation RSStatsSecondVC

static int onceAnimated = 2;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setupContributionGraph];
    [self setupBarChart];
    
}

- (void)setupContributionGraph
{
    self.contributionGraph = [[TEAContributionGraph alloc] initWithFrame:CGRectMake(65, 65, 190, 162)];
    self.contributionGraph.backgroundColor = [UIColor whiteColor];
    self.contributionGraph.width = 22;
    self.contributionGraph.spacing = 6;
    self.contributionGraph.data = @[@0, @1, @0, @0, @0, @4, @0, @5, @0, @0, @0, @3, @0, @0, @0, @5, @0, @0, @6, @0, @0, @0, @3, @0, @3, @0, @4, @0, @5, @0, @0];
    [self.view addSubview:self.contributionGraph];
}

- (void)setupBarChart
{
    self.barChart = [[PNBarChart alloc] initWithFrame:CGRectMake(0, 235.0, SCREEN_WIDTH, 200.0)];
    // barChart UI
    UIColor *myGray = [[UIColor alloc] initWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
    self.barChart.barBackgroundColor = myGray;
    self.barChart.strokeColor = PNTwitterColor;
    // barChart data
    self.barChart.xLabels = @[@"SEP",@"OCT",@"NOV",@"DEC",@"JAN"];
    self.barChart.yValues = @[@1,  @10, @2, @6, @13];
    [self.barChart strokeChart];
    [self.view addSubview:self.barChart];
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
        //[self.barChart strokeChart];
    }
}

@end
