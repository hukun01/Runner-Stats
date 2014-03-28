//
//  RSRankVC.m
//  Runner Stats
//
//  Created by Mr. Who on 3/27/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSRankVC.h"
#import "RSGameKitHelper.h"

@interface RSRankVC ()
@property (strong, nonatomic) IBOutlet UILabel *noticeLabel;

@end

@implementation RSRankVC

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
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[RSGameKitHelper sharedGameKitHelper] authenticateLocalPlayer];
    if ([[RSGameKitHelper sharedGameKitHelper] gameCenterFeaturesEnabled] ) {
        self.noticeLabel.hidden = YES;
        GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
        if (gameCenterController != nil) {
            gameCenterController.gameCenterDelegate = [RSGameKitHelper sharedGameKitHelper];
            gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
            gameCenterController.leaderboardIdentifier = @"me.lifexplorer.Runner_Stats.Best_Runners";
            [self presentViewController:gameCenterController animated:YES completion:nil];
        }
    }
    else {
        self.noticeLabel.hidden = NO;
        self.noticeLabel.text = @"Game center not enabled.";
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
