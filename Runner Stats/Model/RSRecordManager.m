//
//  RSRecordManager.m
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRecordManager.h"

@interface RSRecordManager()
@end

@implementation RSRecordManager

NSString *catalogPath;
NSFileManager *fileManager;
NSMutableArray *allRecords;
double_t overallDistance;
double_t overallTime;
double_t overallSpeed;

+ (double_t)overallDistance
{
    return overallDistance;
}

+ (double_t)overallTime
{
    return overallTime;
}

+ (double_t)overallSpeed
{
    return overallSpeed;
}

+ (void)initialize
{
    catalogPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"record.csv"];
    fileManager = [NSFileManager defaultManager];
    allRecords = [NSMutableArray array];
    [RSRecordManager update];
}

+ (void)update
{
    // update allRecords
    allRecords = [[NSArray arrayWithContentsOfCSVFile:catalogPath] mutableCopy];
    // Check the tail, cut off the row that only contain "".
    if ([allRecords count] > 0) {
        if ([[allRecords lastObject] count] == 1) {
            [allRecords removeLastObject];
        }
    }
    // update overall distance in meters
    // update overall time in seconds
    // update overall average speed in m/s
    overallDistance = 0;
    overallTime     = 0;
    overallSpeed    = 0;
    if ([allRecords count] > 0) {
        for (NSArray *record in allRecords) {
            overallDistance += [[record objectAtIndex:1] doubleValue];
            overallTime     += [[record objectAtIndex:2] intValue];
        }
        overallSpeed = overallDistance / overallTime;
    }
}


+ (BOOL)createCatalog
{
    if (![fileManager fileExistsAtPath:catalogPath])
    {
        if (![fileManager createFileAtPath:catalogPath contents:nil attributes:nil])
        {
            NSLog(@"Catalog creation failed.");
            return NO;
        }
    }
    
    return YES;
}

+ (NSArray *)allRecords
{
    return allRecords;
}

+ (NSArray *)readRecordByPath:(NSString *)path
{
    NSMutableArray *record = [[NSArray arrayWithContentsOfCSVFile:path] mutableCopy];
    // Check the tail, cut off the row that only contain "".
    if ([record count] > 0) {
        if ([[record lastObject] count] == 1) {
            [record removeLastObject];
        }
    }
    return record;
}

+ (void)addCatalogEntry:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    if ([allRecords count] >= 1) {
        NSString *recentRecordDate = [[allRecords lastObject] firstObject];
        recentRecordDate = [[recentRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        NSString *newRecordDate = [newline firstObject];
        newRecordDate = [[newRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        NSDate *recentDate = [df dateFromString:recentRecordDate];
        NSDate *newDate = [df dateFromString:newRecordDate];
        if ([recentDate isEqualToDate:newDate])
        {
            //Only one record in a day.
            [allRecords removeLastObject];
        }
    }
    // add the lastest record
    [allRecords addObject:newline];
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:catalogPath];
    for (NSArray *row in allRecords) {
        [writer writeLineOfFields:row];
    }
    
    [RSRecordManager update];
}

+ (NSString *)subStringFromDateString:(NSString *)dateString
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [df dateFromString:dateString];
    df.dateFormat = @"yyyy-MM";
    return [df stringFromDate:date];
}

+ (void)deleteEntryAt:(NSInteger)row
{
    if (row >= [allRecords count]) {
        return;
    }
    
    // delete associated data file whose name is $date$.csv
    NSString *recordFileName = [[allRecords[row] firstObject] description];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:recordFileName];
    [df setDateFormat:@"yyyy-MM-dd"];
    recordFileName = [df stringFromDate:date];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *recordPath = [docsPath stringByAppendingPathComponent:[recordFileName stringByAppendingString:@".csv"]];
    if (![fileManager removeItemAtPath:recordPath error:NULL]) {
        NSLog(@"Remove data file failed.");
    }
    
    // delete this record summary in catalog: record.csv
    [allRecords removeObjectAtIndex:row];
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:catalogPath];
    for (NSArray *row in allRecords) {
        [writer writeLineOfFields:row];
    }
    
    [RSRecordManager update];
}

+ (NSString *)timeFormatted:(int)totalSeconds
                 withOption:(int)option
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
