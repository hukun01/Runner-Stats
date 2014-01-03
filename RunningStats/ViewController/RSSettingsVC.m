//
//  RSSettingsVC.m
//  RunningStats
//
//  Created by Mr. Who on 12/29/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSSettingsVC.h"

@interface RSSettingsVC ()

@end

@implementation RSSettingsVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        NSLog(@"Settings");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Settings";
    [self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SettingsTVC"]];
    UITableViewController *settingsTVC = [[self childViewControllers] firstObject];
    if (settingsTVC.view.superview == nil) {
        CGRect frame = CGRectMake(0, 187, self.scrollView.frame.size.width, 451);
        settingsTVC.view.frame = frame;
        [self.scrollView addSubview:settingsTVC.tableView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
