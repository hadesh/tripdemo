//
//  DDSearchManager.h
//  TripDemo
//
//  Created by xiaoming han on 15/4/3.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AMapSearchKit/AMapSearchAPI.h>

typedef void(^DDSearchCompletionBlock)(id request, id response, NSError *error);

/**
 *  搜索管理类。对高德搜索SDK进行了封装，使用block回调，无需频繁设置代理。
 */
@interface DDSearchManager : NSObject

+ (instancetype)sharedInstance;

- (void)searchForRequest:(id)request completionBlock:(DDSearchCompletionBlock)block;

@end
