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
             @[@"2013-12-01 16:30:00", @"5341", @"1800", @"3"],
             @[@"2013-12-06 16:32:00", @"5341", @"1802", @"2.3"],
             @[@"2013-12-11 16:34:00", @"5129", @"1800", @"3.4"],
             @[@"2013-12-11 16:34:00", @"5341", @"1800", @"2.2"],
             @[@"2013-12-11 16:34:00", @"5129", @"1920", @"2.5"],
             @[@"2013-12-06 16:32:00", @"5129", @"1822", @"2.6"],
             @[@"2013-12-11 16:34:00", @"5341", @"1855", @"2.9"],
             @[@"2013-12-11 16:34:00", @"5129", @"1866", @"2.20"],
             @[@"2013-12-15 16:28:00", @"5341", @"1850", @"3.3"]
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
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    NSArray *recordContent = [self test_Record];
    for (NSArray *line in recordContent) {
        [writer writeLineOfFields:line];
    }
    
    
    return YES;
}

- (NSArray *)readRecord
{
    NSArray *allRecords = [NSArray arrayWithContentsOfCSVFile:self.recordPath];
    NSRange range = {0, [allRecords count]-1};
    return [allRecords subarrayWithRange:range];
}

- (NSArray *)readRecordDetailsByPath:(NSString *)path
{
    return [NSArray arrayWithContentsOfCSVFile:path];
}

- (void)addALine:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] > 1) {
        NSArray *recentRecord = [allRecords objectAtIndex:([allRecords count]-2)];
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
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:dateString];
    return [df stringFromDate:date];
}

// Delete the last nonempty line in the record
- (void)deleteLastLine
{
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] == 1) {
        return;
    }
    NSRange range = {0, [allRecords count]-1};
    NSArray *newAllRecords = [allRecords subarrayWithRange:range];
    
    if (![[NSFileManager defaultManager] removeItemAtPath:[self recordPath] error:NULL])
        NSLog(@"Remove current record failed.");
    if (![self createRecord]) {
        NSLog(@"Re-create failed.");
    }
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    for (NSArray *a in newAllRecords) {
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
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

@end
