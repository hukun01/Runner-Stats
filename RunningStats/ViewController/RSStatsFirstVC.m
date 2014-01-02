//
//  RSStatsFirstVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/30/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSStatsFirstVC.h"
#import "RSRecordManager.h"
#import "RSRecordCell.h"

#define CELL_HEIGHT 44
#define SECONDS_OF_HOUR 3600

@interface RSStatsFirstVC ()
@property (strong, nonatomic) IBOutlet UITableView *recordTableView;
@property (strong, nonatomic) NSArray *records;
@property (strong, nonatomic) RSRecordManager *recordManager;

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *avgSpeedLabel;
@property (strong, nonatomic) IBOutlet UILabel *avgPaceLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceUnitLabel;
@property (strong, nonatomic) IBOutlet UILabel *paceUnitLabel;


@end

@implementation RSStatsFirstVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        _recordManager = [[RSRecordManager alloc] init];
    }
    return self;
}

- (void)setRecords:(NSArray *)records
{
    NSRange range = {0, [records count]-1};
    
    _records = [records subarrayWithRange:range];
    [self.recordTableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.recordTableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"showRecordDetails"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(showRecordFromName:)]) {
                    NSArray *record = [self.records objectAtIndex:indexPath.row];
                    NSString *recordFileName = [self.recordManager subStringFromDateString:[record firstObject]];
                    recordFileName = [recordFileName stringByAppendingString:@".csv"];
                    [segue.destinationViewController performSelector:@selector(showRecordFromName:) withObject:recordFileName];
                }
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setup];
}

- (void)setup
{
    [self.navigationItem setTitle:@"Summary"];
    
    self.recordTableView.dataSource = self;
    self.recordTableView.delegate = self;
    self.records = [self.recordManager readRecord];
    [self calcWholeDataForLabels];
}

- (void)calcWholeDataForLabels
{
    CLLocationDistance wholeKilometers = 0.0;
    NSTimeInterval wholeSeconds = 0.0;
    CLLocationSpeed averageSpeed = 0.0;
    
    for (NSArray *record in self.records) {
        wholeKilometers += [[record objectAtIndex:1] doubleValue];
        wholeSeconds += [[record objectAtIndex:2] intValue];
        averageSpeed += [[record lastObject] doubleValue];
    }
    
    if (wholeKilometers > 10.0) {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.1f", wholeKilometers];
    }
    else {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.2f", wholeKilometers];
    }
    
    NSString *wholeDurationString = [self.recordManager timeFormatted:wholeSeconds withOption:FORMAT_HHMMSS];
    self.durationLabel.text = wholeDurationString;
    
    int pace = wholeSeconds / wholeKilometers;
    NSString *averagePaceString = [self.recordManager timeFormatted:pace withOption:FORMAT_MMSS];
    self.avgPaceLabel.text = averagePaceString;
    
    averageSpeed /= [self.records count];
    
    if (averageSpeed > 10.0) {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.1f", averageSpeed];
    }
    else {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.2f", averageSpeed];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.records count];
}

- (RSRecordCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"recordCell"];
    RSRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory.png"]];
    
    // Set cell content labels
    cell.textLabel.text = [self cellTitleForIndex:indexPath.row];
    cell.distanceLabel.text = [[self.records objectAtIndex:indexPath.row] objectAtIndex:1];
    int seconds = [[[self.records objectAtIndex:indexPath.row] objectAtIndex:2] intValue];
    if (seconds >= SECONDS_OF_HOUR) {
        cell.durationLabel.text = [self.recordManager timeFormatted:seconds withOption:FORMAT_HHMMSS];
    }
    else {
        cell.durationLabel.text = [self.recordManager timeFormatted:seconds withOption:FORMAT_MMSS];
    }
    
    return cell;
}

- (NSString *)cellTitleForIndex:(NSInteger)index
{
    NSArray *rowContent = [self.records objectAtIndex:index];
    NSString *recordDateString = [[rowContent firstObject] description];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *d = [df dateFromString:recordDateString];
    df.dateFormat = @"MMM dd, yyyy";
    NSString *s = [df stringFromDate:d];
    
    return s;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
