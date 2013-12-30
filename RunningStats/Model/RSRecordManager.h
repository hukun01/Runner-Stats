//
//  RSRecordManager.h
//  RunningStats
//
//  Created by Mr. Who on 12/22/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@interface RSRecordManager : NSObject <CHCSVParserDelegate>
// Create if not exists an empty record named record.csv, in which there is one empty line
// There is always only one record.csv whose structure is as followed.

// Date,Distance,Duration,AvgSpeed
- (BOOL)createRecord;
- (NSArray *)readRecord;
// newline points to a NSArray separated by comma
- (void)addALine:(NSArray *)newline;

@property(strong, nonatomic) NSString *recordPath;

@end
