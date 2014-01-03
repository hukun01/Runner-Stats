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

@end

@implementation RSSettingsTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.scrollEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    RSSettingsVC *parentVC = (RSSettingsVC *)self.navigationController.parentViewController;

    parentVC.scrollView.scrollEnabled = YES;
    parentVC.descriptionLabel.hidden = NO;
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
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


@end
