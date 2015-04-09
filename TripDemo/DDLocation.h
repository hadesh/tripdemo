//
//  DDLocation.h
//  TripDemo
//
//  Created by xiaoming han on 15/4/2.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 *  封装位置信息。
 */
@interface DDLocation : NSObject

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *cityCode;
@property (nonatomic, copy) NSString *address;

@end
