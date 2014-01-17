//
//  RSRecordManager.m
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRecordManager.h"

@implementation RSRecordManager

- (id)init
{
    self = [super init];
    if (self)
    {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        self.recordPath = [docsPath stringByAppendingPathComponent:@"record.csv"];
    }
    return self;
}

//debug
- (NSArray *) test_Record
{
    return @[
             @[@"2013-12-01 16:28:00", @"5341", @"1450", @"3.3"],
             @[@"2013-12-05 16:28:00", @"5341", @"1250", @"3.3"],
             @[@"2013-12-10 16:28:00", @"5341", @"1850", @"3.3"],
             @[@"2013-12-15 16:28:00", @"5341", @"1550", @"3.3"],
             @[@"2013-12-18 16:28:00", @"5341", @"1800", @"3.3"],
             @[@"2013-12-19 16:28:00", @"5341", @"1530", @"3.4"],
             @[@"2013-12-22 16:28:00", @"5341", @"1780", @"3.2"],
             @[@"2014-01-01 16:30:00", @"5341", @"1800", @"3"],
             @[@"2014-01-03 16:34:00", @"5129", @"1776", @"2.20"],
             @[@"2014-01-04 16:32:00", @"5341", @"1802", @"2.3"],
             @[@"2014-01-05 16:32:00", @"5341", @"1702", @"2.3"],
             ];
}

- (BOOL)createRecord
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.recordPath])
    {
        if (![fileManager createFileAtPath:self.recordPath contents:nil attributes:nil])
        {
            NSLog(@"Record creation failed.");
            return NO;
        }
    }
    
    //debug
//    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
//    NSArray *recordContent = [self test_Record];
//    for (NSArray *line in recordContent) {
//        [writer writeLineOfFields:line];
//    }
    //
    
    return YES;
}

- (NSArray *)readRecord
{
    NSMutableArray *allRecords = [[NSArray arrayWithContentsOfCSVFile:self.recordPath] mutableCopy];
    // Check the tail, cut off the row that only contain "".
    if ([allRecords count] > 0) {
        if ([[allRecords lastObject] count] == 1) {
            [allRecords removeLastObject];
        }
    }
    return allRecords;
}

- (NSArray *)readRecordDetailsByPath:(NSString *)path
{
    NSMutableArray *allRecords = [[NSArray arrayWithContentsOfCSVFile:path] mutableCopy];
    // Check the tail, cut off the row that only contain "".
    if ([allRecords count] > 0) {
        if ([[allRecords lastObject] count] == 1) {
            [allRecords removeLastObject];
        }
    }
    return allRecords;
}

- (void)addALine:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] >= 1) {
        NSArray *recentRecord = [allRecords lastObject];
        NSString *recentRecordDate = [recentRecord firstObject];
        recentRecordDate = [[recentRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        NSString *newRecordDate = [newline firstObject];
        newRecordDate = [[newRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        NSDate *recentDate = [df dateFromString:recentRecordDate];
        NSDate *newDate = [df dateFromString:newRecordDate];
        if ([recentDate isEqualToDate:newDate])
        {
            NSLog(@"Only one record in a day.");
            [self deleteLastLine];
        }
    }
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    [writer writeLineOfFields:newline];
}

- (NSString *)subStringFromDateString:(NSString *)dateString
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [df dateFromString:dateString];
    df.dateFormat = @"yyyy-MM";
    return [df stringFromDate:date];
}

// Delete the last nonempty line in the record
- (void)deleteLastLine
{
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] <= 1) {
        NSLog(@"deleteLastLine??");
        [[NSFileManager defaultManager] removeItemAtPath:self.recordPath error:NULL];
        [self createRecord];
        return;
    }
    
    if (![[NSFileManager defaultManager] removeItemAtPath:self.recordPath error:NULL])
        NSLog(@"Remove current record failed.");
    if (![self createRecord]) {
        NSLog(@"Re-create failed.");
    }
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    for (NSArray *a in [allRecords subarrayWithRange:NSMakeRange(0, [allRecords count]-1)]) {
        [writer writeLineOfFields:a];
    }
}

- (NSString *)timeFormatted:(int)totalSeconds withOption:(NSInteger)option
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    if (option == FORMAT_MMSS) {
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
    else if (option == FORMAT_HHMMSS) {
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
    }
}

@end
