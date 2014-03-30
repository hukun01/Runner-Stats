//
//  RSAnnotation.m
//  Runner Stats
//
//  Created by Mr. Who on 3/25/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSAnnotation.h"

@implementation RSAnnotation

- (id)initWithTitle:(NSString *)title
        andLocation:(CLLocationCoordinate2D)location
{
    self = [super init];
    
    if (self) {
        _title = title;
        _coordinate = location;
    }
    return self;
}

- (MKAnnotationView *)annotationView
{
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"RSAnnotationID"];
    annotationView.enabled           = YES;

    UIImageView *bgImg               = [[UIImageView alloc] init];
    bgImg.image                      = [UIImage imageNamed:@"Annotation"];
    bgImg.backgroundColor            = [UIColor clearColor];

    UILabel *label                   = [[UILabel alloc] init];
    label.font                       = [UIFont boldSystemFontOfSize:15];
    label.adjustsFontSizeToFitWidth  = YES;
    label.baselineAdjustment         = UIBaselineAdjustmentAlignCenters;
    label.minimumScaleFactor         = 0.2;
    label.textAlignment              = NSTextAlignmentCenter;
    label.textColor                  = [UIColor whiteColor];
    label.backgroundColor            = [UIColor clearColor];
    label.text                       = self.title;

    annotationView.frame             = CGRectMake(0, 0, 30, 30);
    bgImg.frame                      = annotationView.frame;
    label.frame                      = CGRectMake(0, 0, 19, 19);
    [label setCenter:bgImg.center];
    CGRect labelFrame = label.frame;
    labelFrame.origin.y -= 1;
    label.frame = labelFrame;
    [annotationView addSubview:bgImg];
    [annotationView addSubview:label];
    
    return annotationView;
}

@end
