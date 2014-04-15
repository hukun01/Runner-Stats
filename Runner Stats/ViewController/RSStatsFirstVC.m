//
//  RSStatsFirstVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/30/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSRunningVC.h"
#import "RSStatsFirstVC.h"
#import "RSStatsSecondVC.h"
#import "RSRecordManager.h"
#import "RSRecordCell.h"
#import "RSStatsVC.h"
#import "RSAddRecordVC.h"

#define CELL_HEIGHT 44

@interface RSStatsFirstVC ()
@property (strong, nonatomic) IBOutlet UITableView *recordTableView;
@property (strong, nonatomic) NSArray *records;

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *avgSpeedLabel;
@property (strong, nonatomic) IBOutlet UILabel *avgPaceLabel;

@property (strong, nonatomic) IBOutlet UILabel *distanceUnitLabel;
@property (strong, nonatomic) IBOutlet UILabel *paceUnitLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedUnitLabel;

@property (strong, nonatomic) UIImage *sunImg;
@property (strong, nonatomic) UIImage *moonImg;
@property (strong, nonatomic) NSDate *nightTime;
@property (strong, nonatomic) NSDateFormatter *df;

@end

@implementation RSStatsFirstVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _df = [[NSDateFormatter alloc] init];
        _df.dateFormat = @"HH:mm:ss";
        _nightTime = [_df dateFromString:@"18:00:00"];
        _sunImg = [UIImage imageNamed:@"Sun"];
        _moonImg = [UIImage imageNamed:@"Moon"];
    }
    return self;
}

- (void)setRecords:(NSArray *)records
{
    _records = records;
    [self.recordTableView reloadData];
    // Refresh data labels
    [self calcWholeDataForLabels];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.recordTableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"showRecordDetails"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(showRecordFromDate:)]) {
                    NSArray *record = [self.records objectAtIndex:indexPath.row];
                    NSString *recordFileName = [[record firstObject] description];
                    [segue.destinationViewController performSelector:@selector(showRecordFromDate:) withObject:recordFileName];
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
    [self.navigationItem setTitle:NSLocalizedString(@"Second_1_NavigationBarTitle", nil)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addARecord)];
    // setup table view
    self.recordTableView.dataSource = self;
    self.recordTableView.delegate = self;
}

- (void)addARecord
{
    RSAddRecordVC *addRecordVC =[self.storyboard instantiateViewControllerWithIdentifier:@"AddRecordVC"];
    if (addRecordVC != nil) {
        [self presentViewController:addRecordVC animated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    RSStatsVC *parentVC = (RSStatsVC *)self.navigationController.parentViewController;
    parentVC.pageControl.hidden = NO;
    parentVC.currentStatsView.scrollEnabled = YES;
    // setup data
    self.records = [[[RSRecordManager allRecords] reverseObjectEnumerator] allObjects];
    [self setupUnitLabels];
}

- (void)setupUnitLabels
{
    self.distanceUnitLabel.text = RS_DISTANCE_UNIT_STRING;
    self.paceUnitLabel.text = RS_PACE_UNIT_STRING;
    self.speedUnitLabel.text = RS_SPEED_UNIT_STRING;
}

- (void)calcWholeDataForLabels
{
    if ([self.records count] == 0) {
        self.distanceLabel.text = @"0";
        self.durationLabel.text = @"0";
        self.avgSpeedLabel.text = @"0";
        self.avgPaceLabel.text  = @"0";
        
        return;
    }
    CLLocationDistance wholeMeters = [RSRecordManager overallDistance] / RS_UNIT;
    NSTimeInterval wholeSeconds = [RSRecordManager overallTime];
    CLLocationSpeed averageSpeed = [RSRecordManager overallSpeed];
    
    if (wholeMeters > 10.0) {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.1f", wholeMeters];
    }
    else {
        self.distanceLabel.text = [NSString stringWithFormat:@"%.2f", wholeMeters];
    }
    self.durationLabel.text = [RSRecordManager timeFormatted:wholeSeconds withOption:FORMAT_HHMMSS];
    
    int pace = 0;
    if (wholeMeters == 0) {
        pace = 0;
    }
    else {
        pace = wholeSeconds / wholeMeters;
    }
    NSString *averagePaceString = [RSRecordManager timeFormatted:pace withOption:FORMAT_MMSS];
    self.avgPaceLabel.text = averagePaceString;
    
    averageSpeed *= (SECONDS_OF_HOUR/RS_UNIT);
    if (averageSpeed > 10.0) {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.1f", averageSpeed];
    }
    else {
        self.avgSpeedLabel.text = [NSString stringWithFormat:@"%.2f", averageSpeed];
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.records count];
}

- (RSRecordCell *)tableView:(UITableView *)tableView
      cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"recordCell"];
    RSRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Set cell content labels
    if (indexPath.row >= [self.records count]) {
        return cell;
    }
    NSArray *rowContent = [self.records objectAtIndex:indexPath.row];
    NSString *recordDateString = [[rowContent firstObject] description];
    self.df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [self.df dateFromString:recordDateString];
    self.df.dateFormat = @"MMM dd, yyyy";
    cell.textLabel.text = [self.df stringFromDate:date];
    
    self.df.dateFormat = @"HH:mm:ss";
    NSDate *recordTime = [self.df dateFromString:[self.df stringFromDate:date]];
    // if record time is later than nighttime, use moon img
    if ([recordTime compare:self.nightTime] == NSOrderedDescending) {
        cell.timeImageView.image = self.moonImg;
    }
    else {
        cell.timeImageView.image = self.sunImg;
    }
    
    CLLocationDistance wholeDistance = [[[self.records objectAtIndex:indexPath.row] objectAtIndex:1] doubleValue] / RS_UNIT;
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.2f", wholeDistance];
    cell.unitLabel.text = [@" " stringByAppendingString:RS_DISTANCE_UNIT_STRING];
    int seconds = [[[self.records objectAtIndex:indexPath.row] objectAtIndex:2] intValue];
    cell.durationLabel.text = [RSRecordManager timeFormatted:seconds withOption:FORMAT_HHMMSS];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger realIndex = [self.records count] - indexPath.row - 1;
    [RSRecordManager deleteEntryAt:realIndex];
    self.records = [[[RSRecordManager allRecords] reverseObjectEnumerator] allObjects];
}

- (void)setEditing:(BOOL)editing
          animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.recordTableView setEditing:editing animated:animated];
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
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

@end
