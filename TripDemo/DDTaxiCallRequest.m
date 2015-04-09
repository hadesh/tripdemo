//
//  TaxiCallingRequest.m
//  TripDemo
//
//  Created by yi chen on 4/3/15.
//  Copyright (c) 2015 AutoNavi. All rights reserved.
//

#import "DDTaxiCallRequest.h"

@implementation DDTaxiCallRequest

+ (instancetype)requestFrom:(DDLocation *)start to:(DDLocation *)end
{
    return [[self alloc] initWithStart:start to:end];
}

- (id)initWithStart:(DDLocation *)start to:(DDLocation *)end
{
    if (self = [super init])
    {
        self.start = start;
        self.end = end;
    }
    
    return self;
}

@end
