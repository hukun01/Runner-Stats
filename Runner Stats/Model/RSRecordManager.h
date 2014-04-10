//
//  RSRecordManager.h
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

#define FORMAT_HHMMSS 0
#define FORMAT_MMSS 1
#define FORMAT_HHMM 2

@interface RSRecordManager : NSObject <CHCSVParserDelegate>
// Create if not exists an empty record named record.csv, in which there is one empty line
// There is always only one record.csv whose structure is as followed.

// Date,Distance,Duration,AvgSpeed
+ (BOOL)createCatalog;
+ (NSArray *)readRecordByPath:(NSString *)path;
// newline points to a NSArray separated by comma
+ (void)addCatalogEntry:(NSArray *)newline;
+ (void)deleteEntryAt:(NSInteger)row;
+ (void)update;

+ (NSString *)timeFormatted:(int)totalSeconds withOption:(int)option;
+ (NSString *)subStringFromDateString:(NSString *)dateString;

+ (NSArray *)allRecords;
+ (double_t)overallDistance;
+ (double_t)overallTime;
+ (double_t)overallSpeed;
@end
