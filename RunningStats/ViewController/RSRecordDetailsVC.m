//
//  RSRecordDetailsVC.m
//  RunningStats
//
//  Created by Mr. Who on 1/1/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSRecordDetailsVC.h"

@interface RSRecordDetailsVC ()
// flagPoint is for marking every kilometer or mile covered
@property (assign, nonatomic) NSUInteger flagPoint;
@end

@implementation RSRecordDetailsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.flagPoint = 1000;
}

- (void)showRecordFromName:(NSString *)filename
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *recordPath = [docsPath stringByAppendingPathComponent:filename];
    // TO-DO: Read record content from path
    // TO-DO: Draw figures: lineChart and barChart
    // lineChart for duration-speed
    // barChart for pace
    // TO-DO: Use a dictionary to store {1 km : 06:00},{2 km : 06:15} ...
}

@end
