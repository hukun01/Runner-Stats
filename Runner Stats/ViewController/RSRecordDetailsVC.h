//
//  RSRecordDetailsVC.h
//  RunningStats
//
//  Created by Mr. Who on 1/1/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "JBLineChartView.h"
#import "JBConstants.h"
#import "RSConstants.h"

@interface RSRecordDetailsVC : UIViewController <JBLineChartViewDelegate, JBLineChartViewDataSource>//, ADBannerViewDelegate>
- (void)showRecordFromDate:(NSString *)recordDate;
@property GADBannerView *bannerView;
@end
