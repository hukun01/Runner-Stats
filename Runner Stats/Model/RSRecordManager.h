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
- (BOOL)createRecord;
- (NSArray *)readRecord;
- (NSArray *)readRecordDetailsByPath:(NSString *)path;
// newline points to a NSArray separated by comma
- (void)addALine:(NSArray *)newline;
- (NSString *)timeFormatted:(int)totalSeconds withOption:(NSInteger)option;
- (NSString *)subStringFromDateString:(NSString *)dateString;
- (void)deleteRowAt:(NSInteger)row;

@property(strong, nonatomic) NSString *recordPath;

@end
