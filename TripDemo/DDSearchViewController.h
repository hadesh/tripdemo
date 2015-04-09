//
//  DDSearchViewController.h
//  TripDemo
//
//  Created by xiaoming han on 15/4/3.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDLocation;
@class DDSearchViewController;

@protocol DDSearchViewControllerDelegate <NSObject>
@optional

- (void)searchViewController:(DDSearchViewController *)searchViewController didSelectLocation:(DDLocation *)location;

@end

@interface DDSearchViewController : UIViewController

@property (nonatomic, assign) id<DDSearchViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *city;

@end
