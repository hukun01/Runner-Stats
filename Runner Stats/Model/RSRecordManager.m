//
//  RSRecordManager.m
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRecordManager.h"

@interface RSRecordManager()
@property NSFileManager *fileManager;
@end

@implementation RSRecordManager

- (id)init
{
    self = [super init];
    if (self)
    {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        _catalogPath = [docsPath stringByAppendingPathComponent:@"record.csv"];
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (BOOL)createCatalog
{
    if (![self.fileManager fileExistsAtPath:self.catalogPath])
    {
        if (![self.fileManager createFileAtPath:self.catalogPath contents:nil attributes:nil])
        {
            NSLog(@"Catalog creation failed.");
            return NO;
        }
    }
    
    return YES;
}

- (NSArray *)readCatalog
{
    NSMutableArray *allRecords = [[NSArray arrayWithContentsOfCSVFile:self.catalogPath] mutableCopy];
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

- (void)addALineToCatalog:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    NSArray *allRecords = [self readCatalog];
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
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.catalogPath];
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
    NSArray *allRecords = [self readCatalog];
    
    if (![self.fileManager removeItemAtPath:self.catalogPath error:NULL])
        NSLog(@"Remove current record failed.");
    if (![self createCatalog]) {
        NSLog(@"Re-create failed.");
    }
    // if the file contains only one row, clear the file content
    if ([allRecords count] < 2) {
        return;
    }
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.catalogPath];
    for (NSArray *a in [allRecords subarrayWithRange:NSMakeRange(0, [allRecords count]-1)]) {
        [writer writeLineOfFields:a];
    }
}

- (void)deleteRowAt:(NSInteger)row
{
    NSMutableArray *allRecords = [[self readCatalog] mutableCopy];
    
    
    if (![self.fileManager removeItemAtPath:self.catalogPath error:NULL])
        NSLog(@"Remove current record failed.");
    if (![self createCatalog]) {
        NSLog(@"Re-create failed.");
    }
    // if the file contains only one row, it means that the catalog is empty.
    if ([allRecords count] < 2) {
        return;
    }
    
    // delete associated data file whose name is the date
    NSArray *record = [allRecords objectAtIndex:row];
    NSString *recordFileName = [[record firstObject] description];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:recordFileName];
    [df setDateFormat:@"yyyy-MM-dd"];
    recordFileName = [df stringFromDate:date];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *recordPath = [docsPath stringByAppendingPathComponent:[recordFileName stringByAppendingString:@".csv"]];
    if (![self.fileManager removeItemAtPath:recordPath error:NULL]) {
        NSLog(@"Remove data file failed.");
    }
    
    // delete this record summary in record.csv
    [allRecords removeObjectAtIndex:row];
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.catalogPath];
    for (NSArray *a in [allRecords subarrayWithRange:NSMakeRange(0, [allRecords count])]) {
        [writer writeLineOfFields:a];
    }
    
}

- (NSString *)timeFormatted:(int)totalSeconds withOption:(int)option
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
