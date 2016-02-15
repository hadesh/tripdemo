//
//  DDDriverManager.m
//  TripDemo
//
//  Created by yi chen on 4/3/15.
//  Copyright (c) 2015 AutoNavi. All rights reserved.
//

#import "DDDriverManager.h"
#import <AMapSearchKit/AMapSearchAPI.h>
#import "MANaviRoute.h"
#import "DDSearchManager.h"

@interface DDDriverManager() <AMapSearchDelegate>

@property(nonatomic, strong) DDTaxiCallRequest * currentRequest;
@property(nonatomic, strong) DDDriver * selectDriver;

@property(nonatomic, strong) NSArray * driverPath;
@property(nonatomic, assign) NSUInteger subpathIdx;

@end

@implementation DDDriverManager
{
    
}

//根据mapRect取司机数据
- (void)searchDriversWithinMapRect:(MAMapRect)mapRect
{
    //在mapRect区域里随机生成coordinate
#define MAX_COUNT 50
#define MIN_COUNT 5
    NSUInteger randCount = arc4random() % MAX_COUNT + MIN_COUNT;
    
    NSMutableArray * drivers = [NSMutableArray arrayWithCapacity:randCount];
    for (int i = 0; i < randCount; i++)
    {
        DDDriver * driver = [DDDriver driverWithID:@"京B****" coordinate:[self randomPointInMapRect:mapRect]];
        
        [drivers addObject:driver];
    }

    //回调返回司机数据
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchDoneInMapRect:withDriversResult:timestamp:)])
    {
        [self.delegate searchDoneInMapRect:mapRect withDriversResult:drivers timestamp:[NSDate date].timeIntervalSinceReferenceDate];
    }
    
}

//发送用车请求：起点终点
- (BOOL)callTaxiWithRequest:(DDTaxiCallRequest *)request
{
    if (request.start == nil || request.end == nil)
    {
        return NO;
    }
    
    _currentRequest = request;

    //在起点附近随机生成司机位置
#define startAroundRangeMeters 500.0
    
    MAMapRect startAround = MAMapRectForCoordinateRegion(MACoordinateRegionMakeWithDistance(_currentRequest.start.coordinate, startAroundRangeMeters, startAroundRangeMeters));

    CLLocationCoordinate2D driverLocation = [self randomPointInMapRect:startAround];
    NSLog(@"driverLocation : %f %f", driverLocation.latitude, driverLocation.longitude);
    _selectDriver = [DDDriver driverWithID:@"京B****" coordinate:driverLocation];
    
    //延迟返回司机选择结果
    __weak __typeof(&*self) weakSelf = self;
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(callTaxiDoneWithRequest:Taxi:)])
        {
            [weakSelf.delegate callTaxiDoneWithRequest:_currentRequest Taxi:_selectDriver];
        }
        
        //司机位置更新
        [weakSelf startUpdateLocationForDriver:_selectDriver];

    });
    
    return YES;
}

- (void)startUpdateLocationForDriver:(DDDriver *)driver
{
    [self searchPathFrom:driver.coordinate to:_currentRequest.start.coordinate];
    
}

//找驾车到达乘客位置的路径
- (void)searchPathFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to
{
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:from.latitude
                                           longitude:from.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:to.latitude
                                                longitude:to.longitude];

    __weak __typeof(&*self) weakSelf = self;
    [[DDSearchManager sharedInstance] searchForRequest:navi completionBlock:^(id request, id response, NSError *error) {
        
        AMapRouteSearchResponse *naviResponse = response;

        NSLog(@"%@", naviResponse);
        if (naviResponse.route == nil)
        {
            return;
        }
        
        //路径解析
        MANaviRoute * naviRoute = [MANaviRoute naviRouteForPath:naviResponse.route.paths[0]];
        
        //保存路径串
        weakSelf.driverPath = naviRoute.path;
        weakSelf.subpathIdx = 0;
        
        //开始push给乘客端
        NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(onUpdatingLocation) userInfo:nil repeats:YES];
        [timer fire];

    }];

}

- (void)onUpdatingLocation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onUpdatingLocations:forDriver:)] && _subpathIdx < self.driverPath.count)
    {
        [self.delegate onUpdatingLocations:self.driverPath[_subpathIdx++] forDriver:self.selectDriver];
    }
}

#pragma mark - Utility
- (CLLocationCoordinate2D)randomPointInMapRect:(MAMapRect)mapRect
{
    MAMapPoint result;
    result.x = mapRect.origin.x + arc4random() % (int)(mapRect.size.width);
    result.y = mapRect.origin.y + arc4random() % (int)(mapRect.size.height);
    
    return MACoordinateForMapPoint(result);

}

@end
