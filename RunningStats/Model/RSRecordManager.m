//
//  RSRecordManager.m
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRecordManager.h"
@interface RSRecordManager()
@property(nonatomic,strong) NSString *recordPath;
@end

@implementation RSRecordManager

- (id)init
{
    self = [super init];
    if (self) {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        self.recordPath = [docsPath stringByAppendingPathComponent:@"record.csv"];
    }
    return self;
}

- (void)createRecord
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.recordPath]) {
        if (![fileManager createFileAtPath:self.recordPath contents:nil attributes:nil]) {
            NSLog(@"Record creation failed.");
        }
    }
}

- (NSArray *)readRecord
{
    return [NSArray arrayWithContentsOfCSVFile:self.recordPath];
}

- (void)addALine:(NSArray *)newline
{
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToCSVFile:self.recordPath];
    [writer writeLineOfFields:newline];
}
@end
