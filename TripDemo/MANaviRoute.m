//
//  MANaviRoute.m
//  OfficialDemo3D
//
//  Created by yi chen on 1/7/15.
//  Copyright (c) 2015 songjian. All rights reserved.
//

#import "MANaviRoute.h"
#import "CommonUtility.h"

@implementation MANaviRoute

#pragma mark - Format Search Result

/* polyline parsed from search result. */

+ (NSArray *)pathForStep:(AMapStep *)step
{
    if (step == nil)
    {
        return nil;
    }
    
    return [CommonUtility pathForCoordinateString:step.polyline];
}

#pragma mark - Life Cycle

+ (instancetype)naviRouteForPath:(AMapPath *)path
{
    return [[self alloc] initWithPath:path];
}

- (id)initWithPath:(AMapPath *)path
{
    self = [self init];
    
    if (self == nil)
    {
        return nil;
    }
    
    if (path == nil || path.steps.count == 0)
    {
        return self;
    }
    
    NSMutableArray *temp_path = [NSMutableArray array];
    
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        
        NSArray *stepPath = [MANaviRoute pathForStep:step];
        
        if (stepPath != nil)
        {
            [temp_path addObject:stepPath];
        }
    }];
    
    self.path = temp_path;
    
    return self;

}

@end
