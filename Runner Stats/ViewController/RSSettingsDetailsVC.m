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

@interface RSSettingsDetailsVC () <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSURL *url;

@end

@implementation RSSettingsDetailsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hideElementsOfParentVC];
    [self setupWebView];
    CGAffineTransform transform = CGAffineTransformMakeScale(2.0f, 2.0f);
    self.activityIndicator.transform = transform;
    self.activityIndicator.hidden = NO;
}

- (void)hideElementsOfParentVC
{
    RSSettingsVC *parentVC = (RSSettingsVC *)self.parentViewController.navigationController.parentViewController;
    parentVC.scrollView.scrollEnabled = NO;
    parentVC.descriptionLabel.hidden = YES;
}

- (void)setupWebView
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    self.webView.delegate = self;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    [self.webView loadRequest:request];
}

#pragma mark - webview delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
}

- (void)webView:(UIWebView *)webView
didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
}

#pragma mark - segue selector
- (void)showAppSuportPage
{
    self.url = [NSURL URLWithString:@"http://lifexplorer.me/projects/runner-stats/#respond"];
}

- (void)showOpenSourceLibs
{
    self.url = [NSURL URLWithString:@"http://lifexplorer.me/projects/runner-stats/special-thanks/#page"];
}

- (void)showVersionLog
{
    self.url = [NSURL URLWithString:@"http://lifexplorer.me/projects/runner-stats/version-log"];
}
@end
