//
//  RSAnnotation.h
//  Runner Stats
//
//  Created by Mr. Who on 3/25/14.
//  Copyright (c) 2014 hk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface RSAnnotation : NSObject <MKAnnotation>

@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;

- (id)initWithTitle:(NSString *)title andLocation:(CLLocationCoordinate2D)location;
- (MKAnnotationView *)annotationView;

@end
