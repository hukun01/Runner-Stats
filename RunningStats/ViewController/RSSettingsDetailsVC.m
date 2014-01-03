//
//  RSSettingsDetailsVC.m
//  RunningStats
//
//  Created by Mr. Who on 1/2/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSSettingsDetailsVC.h"
#import "RSSettingsTVC.h"
#import "RSSettingsVC.h"

@interface RSSettingsDetailsVC ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURL *url;

@end

@implementation RSSettingsDetailsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    
    RSSettingsVC *parentVC = (RSSettingsVC *)self.parentViewController.navigationController.parentViewController;
    parentVC.scrollView.scrollEnabled = NO;
    parentVC.descriptionLabel.hidden = YES;
}

-(void)showSettingDetailsByTag:(NSNumber *)tag
{
    if ([tag isEqualToNumber:SUPPORT_URL]) {
        self.url = [NSURL URLWithString:@"http://lifexplorer.me/projects/running-stats/#respond"];
    }
    else {
        self.url = [NSURL URLWithString:@"http://lifexplorer.me/projects/running-stats/libraries-used-in-running-stats/#page"];
    }
}

@end
