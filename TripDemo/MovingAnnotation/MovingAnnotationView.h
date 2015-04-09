//
//  MovingAnnotationView.h
//  test
//
//  Created by yi chen on 14-9-3.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

/**
 *  可以在路径上进行移动动画的annoationView。
 */
@interface MovingAnnotationView : MAAnnotationView

- (void)addTrackingAnimationForCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count duration:(CFTimeInterval)duration;

@end
