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
    return [NSArray arrayWithContentsOfCSVFile:self.recordPath];
}

- (void)addALine:(NSArray *)newline
{
    // Need to check if there is already a record with same date
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] > 1) {
        NSArray *recentRecord = [allRecords objectAtIndex:([allRecords count]-2)];
        // debug
        NSLog(@"0 of %lu: %@", [allRecords count], recentRecord);
        
        NSString *recentRecordDate = [recentRecord firstObject];
        recentRecordDate = [[recentRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        NSString *newRecordDate = [newline firstObject];
        newRecordDate = [[newRecordDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        NSDate *recentDate = [df dateFromString:recentRecordDate];
        NSDate *newDate = [df dateFromString:newRecordDate];
        NSLog(@"%@ and %@", [df stringFromDate:recentDate], newDate);
        if ([recentDate isEqualToDate:newDate])
        {
            NSLog(@"Only one record in a day.");
            [self deleteLastLine];
        }
    }
    
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    [writer writeLineOfFields:newline];
}

// Delete the last nonempty line in the record
- (void)deleteLastLine
{
    NSArray *allRecords = [self readRecord];
    if ([allRecords count] == 1) {
        return;
    }
    NSRange range = {0, [allRecords count]-2};
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
@end
