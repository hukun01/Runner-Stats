//
//  RSStatsSecondVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/30/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSStatsSecondVC.h"
#import "PNChart.h"

@interface RSStatsSecondVC ()
@property (strong, nonatomic) IBOutlet PNBarChart *barChart;
//@property (strong, nonatomic) PNBarChart * barChart;
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
    // barChart UI
    UIColor *myGray = [[UIColor alloc] initWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
    [self.barChart setBarBackgroundColor:myGray];
    [self.barChart setStrokeColor:PNTwitterColor];
    // barChart data
    [self.barChart setXLabels:@[@"SEP 1",@"SEP 2",@"SEP 3",@"SEP 4",@"SEP 5"]];
    [self.barChart setYValues:@[@1,  @10, @2, @6, @13]];
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
    }
}

@end
