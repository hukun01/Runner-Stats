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
    
    return YES;
}

- (NSArray *)readRecord
{
    NSArray *allRecords = [NSArray arrayWithContentsOfCSVFile:self.recordPath];
    // Check the tail, cut off the row that only contain "".
    NSInteger invalidTail = [allRecords count]-1;
    while (invalidTail >= 0) {
        if ([[allRecords objectAtIndex:invalidTail] count] == 1) {
            --invalidTail;
        }
        else {
            break;
        }
    }
    NSRange range = {0, invalidTail + 1};
    return [allRecords subarrayWithRange:range];
}

- (NSArray *)readRecordDetailsByPath:(NSString *)path
{
    NSArray *detailData = [NSArray arrayWithContentsOfCSVFile:path];
    NSRange range = {0, [detailData count]-1};
    return [detailData subarrayWithRange:range];
}

- (void)addALine:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] >= 1) {
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
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [df dateFromString:dateString];
    df.dateFormat = @"yyyy-MM";
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
    else if (option == FORMAT_HHMMSS) {
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
    }
}

@end
