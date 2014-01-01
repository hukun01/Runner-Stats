//
//  RSSecondViewController.m
//  RunningStats
//
//  Created by Mr. Who on 12/20/13.
//  Copyright (c) 2013 hk. All rights reserved.
//

#import "RSStatsVC.h"

@interface RSStatsVC ()

@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *currentStatsView;
@property (assign, nonatomic) NSUInteger lastPageNum;
@end

@implementation RSStatsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.currentStatsView setPagingEnabled:YES];
	[self.currentStatsView setScrollEnabled:YES];
	[self.currentStatsView setDelegate:self];
    
    [self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"StatsFirstVC"]];
    [self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"StatsSecondVC"]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder]) {
        [self.pageControl setNumberOfPages:2];
        [self.pageControl setCurrentPage:0];
        self.lastPageNum = 0;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	for (NSUInteger i =0; i < [self.childViewControllers count]; i++) {
		[self loadScrollViewWithPage:i];
	}
	
	self.pageControl.currentPage = self.lastPageNum;
	[self.pageControl setNumberOfPages:[self.childViewControllers count]];
	
	UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
	if (viewController.view.superview != nil) {
		[viewController viewWillAppear:animated];
	}
	
	self.currentStatsView.contentSize = CGSizeMake(_currentStatsView.frame.size.width * [self.childViewControllers count], _currentStatsView.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if ([self.childViewControllers count]) {
		UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
		if (viewController.view.superview != nil) {
			[viewController viewDidAppear:animated];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	if ([self.childViewControllers count]) {
		UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
		if (viewController.view.superview != nil) {
			[viewController viewWillDisappear:animated];
		}
        self.lastPageNum = self.pageControl.currentPage;
	}
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
	if (viewController.view.superview != nil) {
		[viewController viewDidDisappear:animated];
	}
	[super viewDidDisappear:animated];
}

- (void)loadScrollViewWithPage:(NSUInteger)page {
    if (page >= [self.childViewControllers count])
        return;
    
	// replace the placeholder if necessary
    UIViewController *controller = [self.childViewControllers objectAtIndex:page];
    if (controller == nil) {
		return;
    }
	
	// add the controller's view to the scroll view
    if (controller.view.superview == nil) {
        CGRect frame = self.currentStatsView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.currentStatsView addSubview:controller.view];
    }
}

- (IBAction)changePage:(id)sender
{
    NSUInteger page = ((UIPageControl *)sender).currentPage;
	// update the scroll view to the appropriate page
    CGRect frame = self.currentStatsView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    
    UIViewController *previousVC = [self.childViewControllers objectAtIndex:1-page];
    UIViewController *currentVC = [self.childViewControllers objectAtIndex:page];
    [previousVC viewWillDisappear:YES];
    [currentVC viewWillAppear:YES];
    
    [self.currentStatsView scrollRectToVisible:frame animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    UIViewController *previousVC = [self.childViewControllers objectAtIndex:1-self.pageControl.currentPage];
    UIViewController *currentVC = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [previousVC viewDidDisappear:YES];
    [currentVC viewDidAppear:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.currentStatsView.frame.size.width;
    int page = floor((self.currentStatsView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    page = page > 1 ? 1 : page;
    page = page < 0 ? 0 : page;
	if (self.pageControl.currentPage != page) {
		UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
		UIViewController *newViewController = [self.childViewControllers objectAtIndex:page];
		[oldViewController viewWillDisappear:YES];
		[newViewController viewWillAppear:YES];
		self.pageControl.currentPage = page;
		[oldViewController viewDidDisappear:YES];
		[newViewController viewDidAppear:YES];
	}
}

@end
