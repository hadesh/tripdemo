//
//  DDDriverManager.h
//  TripDemo
//
//  Created by yi chen on 4/3/15.
//  Copyright (c) 2015 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import "DDTaxiCallRequest.h"
#import "DDDriver.h"

@protocol DDDriverManagerDelegate;

@interface DDDriverManager : NSObject

@property (nonatomic, weak) id<DDDriverManagerDelegate> delegate;

//根据mapRect取司机数据
- (void)searchDriversWithinMapRect:(MAMapRect)mapRect;

//发送用车请求：起点终点
- (BOOL)callTaxiWithRequest:(DDTaxiCallRequest *)request;

@end

@protocol DDDriverManagerDelegate <NSObject>
@optional

//返回司机数据结果
- (void)searchDoneInMapRect:(MAMapRect)mapRect withDriversResult:(NSArray *)drivers timestamp:(NSTimeInterval)timestamp;

//司机选择结果
- (void)callTaxiDoneWithRequest:(DDTaxiCallRequest *)request Taxi:(DDDriver *)driver;

//司机位置更新
- (void)onUpdatingLocations:(NSArray *)locations forDriver:(DDDriver *)driver;

@end
