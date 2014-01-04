//
//  RSConstants.h
//  RunningStats
//
//  Created by Mr. Who on 1/3/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import <iAd/iAd.h>

#ifndef RunningStats_RSConstants_h
#define RunningStats_RSConstants_h

#define RS_UNIT ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? 1000.0 : 1609.34)
#define RS_DISTANCE_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"km" : @"mi")
#define RS_SPEED_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"km/h" : @"mi/h")
#define RS_SPEED_UNIT_SHORT_STRING  ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"kph" : @"mph")
#define RS_PACE_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"min/km" : @"min/mi")
#define RS_VOICE_ON [[NSUserDefaults standardUserDefaults] boolForKey:@"voiceSwitch"]
#define RS_COUNT_DOWN ([[NSUserDefaults standardUserDefaults] integerForKey:@"countDown"]==0 ? 0 : ([[NSUserDefaults standardUserDefaults] integerForKey:@"countDown"]==1 ? 5 : 10))

#define SECONDS_OF_HOUR 3600

#define RS_JAN NSLocalizedString(@"JAN", nil)
#define RS_FEB NSLocalizedString(@"FEB", nil)
#define RS_MAR NSLocalizedString(@"MAR", nil)
#define RS_APR NSLocalizedString(@"APR", nil)
#define RS_MAY NSLocalizedString(@"MAY", nil)
#define RS_JUN NSLocalizedString(@"JUN", nil)
#define RS_JUL NSLocalizedString(@"JUL", nil)
#define RS_AUG NSLocalizedString(@"AUG", nil)
#define RS_SEP NSLocalizedString(@"SEP", nil)
#define RS_OCT NSLocalizedString(@"OCT", nil)
#define RS_NOV NSLocalizedString(@"NOV", nil)
#define RS_DEC NSLocalizedString(@"DEC", nil)

#endif
