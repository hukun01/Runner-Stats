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
@property (strong, nonatomic) PNBarChart * barChart;
@end

@implementation RSStatsSecondVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        if (!self.barChart) {
            self.barChart = [[PNBarChart alloc] initWithFrame:CGRectMake(0, 135.0, SCREEN_WIDTH, 200.0)];
            [self.barChart setXLabels:@[@"SEP 1",@"SEP 2",@"SEP 3",@"SEP 4",@"SEP 5"]];
            [self.barChart setYValues:@[@1,  @10, @2, @6, @3]];
            [self.barChart strokeChart];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.view addSubview:self.barChart];
    
}
@end
