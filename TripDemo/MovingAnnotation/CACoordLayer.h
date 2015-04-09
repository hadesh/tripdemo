//
//  CACoordLayer.h
//  test
//
//  Created by yi chen on 14-9-3.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface CACoordLayer : CALayer

@property (nonatomic, assign) MAMapView * mapView;

@property (nonatomic) double mapx;

@property (nonatomic) double mapy;

@property (nonatomic) CGPoint centerOffset;

@end


@interface MAMapView(Additional)

- (CGPoint)pointForMapPoint:(MAMapPoint)mapPoint;

@end