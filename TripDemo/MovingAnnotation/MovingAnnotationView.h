//
//  MovingAnnotationView.h
//  test
//
//  Created by yi chen on 14-9-3.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface MovingAnnotationView : MAPinAnnotationView

- (void)addTrackingAnimationForCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count duration:(CFTimeInterval)duration;

@end
