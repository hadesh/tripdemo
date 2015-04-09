//
//  DDLocation.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/2.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "DDLocation.h"

@implementation DDLocation

- (NSString *)description
{
    return [NSString stringWithFormat:@"name:%@, cityCode:%@, address:%@, coordinate:%f, %f", self.name, self.cityCode, self.address, self.coordinate.latitude, self.coordinate.longitude];
}

@end
