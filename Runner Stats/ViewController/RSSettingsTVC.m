//
//  RSSettingsTVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/30/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSSettingsTVC.h"
#import "RSSettingsVC.h"

@interface RSSettingsTVC ()
@property (strong, nonatomic) IBOutlet UISegmentedControl *measureUnitSegControl;
@property (strong, nonatomic) IBOutlet UISwitch *voiceSwitch;
@property (strong, nonatomic) IBOutlet UISegmentedControl *countDownSegControl;

@end

@implementation RSSettingsTVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // read user preferences if it exists
    [self setupUserDefaults];
}

- (void)setupUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.measureUnitSegControl.selectedSegmentIndex = [defaults integerForKey:@"measureUnit"];
    self.voiceSwitch.on = [defaults boolForKey:@"voiceSwitch"];
    self.countDownSegControl.selectedSegmentIndex = [defaults integerForKey:@"countDown"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    RSSettingsVC *parentVC = (RSSettingsVC *)self.parentViewController;

    parentVC.scrollView.scrollEnabled = YES;
    parentVC.descriptionLabel.hidden = NO;
}

- (IBAction)changeMeasureUnit
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.measureUnitSegControl.selectedSegmentIndex forKey:@"measureUnit"];
    [defaults synchronize];
}

- (IBAction)toggleVoiceSwitch
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.voiceSwitch.on forKey:@"voiceSwitch"];
    [defaults synchronize];
}

- (IBAction)changeCountDown
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.countDownSegControl.selectedSegmentIndex forKey:@"countDown"];
    [defaults synchronize];
}

# pragma mark - segue tableview delegate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"showSettingDetails"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(showSettingDetailsByTag:)]) {
                    NSNumber *tag = @0;
                    if (indexPath.row == 1) {
                        tag = SUPPORT_URL;
                    }
                    else if (indexPath.row == 2) {
                        tag = LIBRARIES_URL;
                    }
                    [segue.destinationViewController performSelector:@selector(showSettingDetailsByTag:) withObject:tag];
                }
            }
        }
    }
}
// setup rate me table view cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        NSString *appName = [NSString stringWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
        NSURL *appStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.com/app/%@",[appName stringByReplacingOccurrencesOfString:@" " withString:@""]]];
        [[UIApplication sharedApplication] openURL:appStoreURL];
    }
}
@end
