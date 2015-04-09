//
//  MANaviRoute.h
//  OfficialDemo3D
//
//  Created by yi chen on 1/7/15.
//  Copyright (c) 2015 songjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>

@interface MANaviRoute : NSObject

@property (nonatomic, strong) NSArray * path;

+ (instancetype)naviRouteForPath:(AMapPath *)path;

- (id)initWithPath:(AMapPath *)path;

@end
