//
//  RSConstants.h
//  RunningStats
//
//  Created by Mr. Who on 1/3/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#ifndef RunningStats_RSConstants_h
#define RunningStats_RSConstants_h

#define RS_UNIT ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? 1000.0 : 1609.34)
#define RS_DISTANCE_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"km" : @"mi")
#define RS_SPEED_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"km/h" : @"mi/h")
#define RS_SPEED_UNIT_SHORT_STRING  ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"kph" : @"mph")
#define RS_PACE_UNIT_STRING ([[NSUserDefaults standardUserDefaults] integerForKey:@"measureUnit"]==0 ? @"min/km" : @"min/mi")
#define RS_VOICE_ON [[NSUserDefaults standardUserDefaults] boolForKey:@"voiceSwitch"]
#define RS_COUNT_DOWN ([[NSUserDefaults standardUserDefaults] integerForKey:@"countDown"]==0 ? 5 : 10)

#define SECONDS_OF_HOUR 3600

#endif
