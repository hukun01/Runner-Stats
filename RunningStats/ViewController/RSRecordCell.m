//
//  RSRecordCell.m
//  RunningStats
//
//  Created by Mr. Who on 1/1/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import "RSRecordCell.h"

@implementation RSRecordCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        UIColor *myBlue = [[UIColor alloc] initWithRed:66.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:0.75];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView.backgroundColor = myBlue;
        UIBezierPath *rounded = [UIBezierPath
                                 bezierPathWithRoundedRect:self.selectedBackgroundView.bounds
                                 byRoundingCorners:UIRectCornerAllCorners
                                 cornerRadii:CGSizeMake(8.0f, 8.0f)];
        
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        [shape setPath:rounded.CGPath];
        self.selectedBackgroundView.layer.mask = shape;
        rounded = nil;
        shape = nil;
        
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selectedAccessory.png"]];
    }
    else {
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory.png"]];
    }
}

@end
