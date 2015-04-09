//
//  DDDriver.h
//  TripDemo
//
//  Created by yi chen on 4/3/15.
//  Copyright (c) 2015 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface DDDriver : NSObject

@property (nonatomic, strong) NSString * idInfo;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

+ (instancetype)driverWithID:(NSString *)idInfo coordinate:(CLLocationCoordinate2D)coordinate;

- (id)initWithID:(NSString *)idInfo coordinate:(CLLocationCoordinate2D)coordinate;

@end
