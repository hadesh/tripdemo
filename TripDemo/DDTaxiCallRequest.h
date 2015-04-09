//
//  TaxiCallingRequest.h
//  TripDemo
//
//  Created by yi chen on 4/3/15.
//  Copyright (c) 2015 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLocation.h"

/**
 *  用车请求对象。
 */
@interface DDTaxiCallRequest : NSObject

@property (nonatomic, strong) DDLocation * start;

@property (nonatomic, strong) DDLocation * end;

@property (nonatomic, strong) NSString * info;

+ (instancetype)requestFrom:(DDLocation *)start to:(DDLocation *)end;

- (id)initWithStart:(DDLocation *)start to:(DDLocation *)end;

@end
