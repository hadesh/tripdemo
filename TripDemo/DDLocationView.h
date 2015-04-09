//
//  DDLocationView.h
//  TripDemo
//
//  Created by xiaoming han on 15/4/2.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDLocation;
@class DDLocationView;

@protocol DDLocationViewDelegate <NSObject>
@optional

- (void)didClickStartLocation:(DDLocationView *)locationView;
- (void)didClickEndLocation:(DDLocationView *)locationView;

@end

@interface DDLocationView : UIView

@property (nonatomic, assign) id<DDLocationViewDelegate> delegate;

@property (nonatomic, strong) DDLocation *startLocation;
@property (nonatomic, strong) DDLocation *endLocation;
@property (nonatomic, copy) NSString *info;

@end
