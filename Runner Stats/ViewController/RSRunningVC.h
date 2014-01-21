//
//  RSFirstViewController.h
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "RSRecordManager.h"
#import "RSPath.h"
#import "RSConstants.h"

@interface RSRunningVC : UIViewController
<MKMapViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, AVSpeechSynthesizerDelegate, ADBannerViewDelegate>

+ (BOOL)updateState;
@end
