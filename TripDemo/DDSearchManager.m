//
//  DDSearchManager.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/3.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "DDSearchManager.h"

@interface DDSearchManager ()<AMapSearchDelegate>
{
    AMapSearchAPI *_search;
    NSMapTable *_mapTable;
}
@end

@implementation DDSearchManager

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _search  = [[AMapSearchAPI alloc] initWithSearchKey:@"c51c42708d693e61c4a89e7b4fea195f" Delegate:self];
        
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsCopyIn];
    }
    return self;
}

- (void)searchForRequest:(id)request completionBlock:(DDSearchCompletionBlock)block
{
    if ([request isKindOfClass:[AMapPlaceSearchRequest class]])
    {
        [_search AMapPlaceSearch:request];
    }
    else if ([request isKindOfClass:[AMapNavigationSearchRequest class]])
    {
        [_search AMapNavigationSearch:request];
    }
    else if ([request isKindOfClass:[AMapInputTipsSearchRequest class]])
    {
        [_search AMapInputTipsSearch:request];
    }
    else if ([request isKindOfClass:[AMapGeocodeSearchRequest class]])
    {
        [_search AMapGeocodeSearch:request];
    }
    else if ([request isKindOfClass:[AMapReGeocodeSearchRequest class]])
    {
        [_search AMapReGoecodeSearch:request];
    }
    else
    {
        NSLog(@"unsupported request");
        return;
    }
    
    [_mapTable setObject:block forKey:request];
}

#pragma mark - Helpers

- (void)performBlockWithRequest:(id)request withResponse:(id)response
{
    DDSearchCompletionBlock block = [_mapTable objectForKey:request];
    if (block)
    {
        block(request, response, nil);
    }
    
    [_mapTable removeObjectForKey:request];
}

#pragma mark - AMapSearchDelegate

- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    DDSearchCompletionBlock block = [_mapTable objectForKey:request];
    
    if (block)
    {
        block(request, nil, error);
    }
    
    [_mapTable removeObjectForKey:request];
}

- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    [self performBlockWithRequest:request withResponse:response];
}

- (void)onNavigationSearchDone:(AMapNavigationSearchRequest *)request response:(AMapNavigationSearchResponse *)response
{
    [self performBlockWithRequest:request withResponse:response];
}

- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response
{
    [self performBlockWithRequest:request withResponse:response];
}

- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response
{
    [self performBlockWithRequest:request withResponse:response];
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    [self performBlockWithRequest:request withResponse:response];
}

@end
