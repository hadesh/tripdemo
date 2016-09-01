//
//  ViewController.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/2.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import "DDLocation.h"
#import "DDSearchViewController.h"
#import "DDSearchManager.h"

#import "DDDriverManager.h"
#import "DDLocationView.h"

#import "Toast+UIView.h"
#import "MovingAnnotationView.h"

typedef NS_ENUM(NSUInteger, DDState) {
    DDState_Init = 0,  //初始状态，显示选择终点
    DDState_Confirm_Destination, //选定起始点和目的地，显示马上叫车
    DDState_Call_Taxi, //正在叫车，显示我已上车
    DDState_On_Taxi, //正在车上状态，显示支付
    DDState_Finish_pay //到达终点，显示评价
};

#define kLocationViewMargin     20
#define kButtonMargin           20
#define kButtonHeight           40
#define kAppName                @"德德用车"

@interface ViewController ()<MAMapViewDelegate, DDSearchViewControllerDelegate, DDDriverManagerDelegate, DDLocationViewDelegate>
{
    MAMapView *_mapView;
    UIView * _messageView;
    
    DDDriverManager * _driverManager;
    NSArray * _drivers;
    MAPointAnnotation * _selectedDriver;
    
    UIButton *_buttonAction;
    UIButton *_buttonCancel;
    UIButton *_buttonLocating;
    
    int _currentSearchLocation; //0 start, 1 end
    BOOL _needsFirstLocating;
}

@property (nonatomic, strong) DDLocation * currentLocation;
@property (nonatomic, strong) DDLocation * destinationLocation;

@property (nonatomic, assign) DDState state;

@property (nonatomic, strong) DDLocationView *locationView;
@property (nonatomic, assign) BOOL isLocating;

@end

@implementation ViewController

#pragma mark - search
- (void)searchReGeocodeWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    
    regeo.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    regeo.requireExtension = YES;
    
    __weak __typeof(&*self) weakSelf = self;
    [[DDSearchManager sharedInstance] searchForRequest:regeo completionBlock:^(id request, id response, NSError *error) {
        if (error)
        {
            NSLog(@"error :%@", error);
        }
        else
        {
            AMapReGeocodeSearchResponse * regeoResponse = response;
            if (regeoResponse.regeocode != nil)
            {
                if (regeoResponse.regeocode.pois.count > 0)
                {
                    AMapPOI *poi = regeoResponse.regeocode.pois[0];
                    
                    weakSelf.currentLocation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
                    weakSelf.currentLocation.name = poi.name;
                    
                    weakSelf.currentLocation.address = poi.address;
                }
                else
                {
                    weakSelf.currentLocation.coordinate = CLLocationCoordinate2DMake(regeoResponse.regeocode.addressComponent.streetNumber.location.latitude, regeoResponse.regeocode.addressComponent.streetNumber.location.longitude);
                    weakSelf.currentLocation.name = [NSString stringWithFormat:@"%@%@%@%@%@", regeoResponse.regeocode.addressComponent.township, regeoResponse.regeocode.addressComponent.neighborhood, regeoResponse.regeocode.addressComponent.streetNumber.street, regeoResponse.regeocode.addressComponent.streetNumber.number, regeoResponse.regeocode.addressComponent.building];
                    
                    weakSelf.currentLocation.address = regeoResponse.regeocode.formattedAddress;
                }
                
                weakSelf.currentLocation.cityCode = regeoResponse.regeocode.addressComponent.citycode;
                weakSelf.isLocating = NO;
                NSLog(@"currentLocation:%@", weakSelf.currentLocation);
            }
        }
    }];
}

#pragma mark - mapView delegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (_needsFirstLocating && updatingLocation)
    {
        [self actionLocating:nil];
        _needsFirstLocating = NO;
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    /* 自定义userLocation对应的annotationView. */
    if ([annotation isKindOfClass:[MAUserLocation class]])
    {
        static NSString *userLocationStyleReuseIndetifier = @"userLocationReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        UIImage *image = [UIImage imageNamed:@"icon_passenger"];
        annotationView.image = image;
        annotationView.centerOffset = CGPointMake(0, -22);
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"driverReuseIndetifier";
        
        MovingAnnotationView *annotationView = (MovingAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MovingAnnotationView alloc] initWithAnnotation:annotation
                                                              reuseIdentifier:pointReuseIndetifier];
        }
        
        UIImage *image = [UIImage imageNamed:@"icon_taxi"];
        
        annotationView.image = image;
        annotationView.centerOffset = CGPointMake(0, -22);
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    return nil;
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = kAppName;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _needsFirstLocating = YES;
    _isLocating = NO;
    _currentSearchLocation = -1;
    
    _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    _mapView.showsIndoorMap = NO;
    _mapView.showsCompass = NO;
    _mapView.rotateEnabled = NO;
    _mapView.showsScale = NO;

    // 去除精度圈。
    _mapView.customizeUserLocationAccuracyCircleRepresentation = YES;
    [self.view addSubview:_mapView];
    
    _driverManager = [[DDDriverManager alloc] init];
    _driverManager.delegate = self;
    
    // controls
    _buttonAction = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonAction.backgroundColor = [UIColor colorWithRed:13.0/255.0 green:79.0/255.0 blue:139.0/255.0 alpha:1.0];
    _buttonAction.layer.cornerRadius = 6;
    _buttonAction.layer.shadowColor = [UIColor blackColor].CGColor;
    _buttonAction.layer.shadowOffset = CGSizeMake(1, 1);
    _buttonAction.layer.shadowOpacity = 0.5;
    
    [self.view addSubview:_buttonAction];
    
    _buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonCancel.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    _buttonCancel.layer.cornerRadius = 6;
    _buttonCancel.layer.shadowColor = [UIColor blackColor].CGColor;
    _buttonCancel.layer.shadowOffset = CGSizeMake(1, 1);
    _buttonCancel.layer.shadowOpacity = 0.5;
    [_buttonCancel setTitle:@"取消" forState:UIControlStateNormal];

    [_buttonCancel addTarget:self action:@selector(actionCancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonCancel];
    
   
    _buttonLocating = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonLocating setImage:[UIImage imageNamed:@"location"] forState:UIControlStateNormal];
    _buttonLocating.backgroundColor = [UIColor whiteColor];
    _buttonLocating.layer.cornerRadius = 6;
    _buttonLocating.layer.shadowColor = [UIColor blackColor].CGColor;
    _buttonLocating.layer.shadowOffset = CGSizeMake(1, 1);
    _buttonLocating.layer.shadowOpacity = 0.5;
    
    [_buttonLocating addTarget:self action:@selector(actionLocating:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_buttonLocating];

    
    _currentLocation = [[DDLocation alloc] init];
    _locationView = [[DDLocationView alloc] initWithFrame:CGRectMake(kLocationViewMargin, kLocationViewMargin, CGRectGetWidth(self.view.bounds) - kLocationViewMargin * 2, 44)];
    _locationView.delegate = self;
    _locationView.startLocation = _currentLocation;
    
    [self.view addSubview:_locationView];

    [self setState:DDState_Init];
}

- (void)viewDidAppear:(BOOL)animated
{
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    _mapView.showsUserLocation = NO;
    _mapView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    _mapView.frame = self.view.bounds;
    
    _buttonCancel.frame = CGRectMake(kButtonMargin, CGRectGetHeight(self.view.bounds) - kButtonMargin - kButtonHeight, CGRectGetMaxX(self.view.bounds) - kButtonMargin * 2, kButtonHeight);
    
    _buttonAction.frame = CGRectMake(kButtonMargin, CGRectGetMinY(_buttonCancel.frame) - kButtonMargin / 2.0 - kButtonHeight, CGRectGetMaxX(self.view.bounds) - kButtonMargin * 2, kButtonHeight);
    
    _buttonLocating.frame = CGRectMake(kButtonMargin, CGRectGetMinY(_buttonAction.frame) - kButtonMargin - kButtonHeight, kButtonHeight, kButtonHeight);
}

#pragma mark - Action

- (void)actionAddEnd:(UIButton *)sender
{
    NSLog(@"actionAddEnd");
    
    if (_currentLocation.cityCode.length == 0)
    {
        NSLog(@"the city have not been located");
        return;
    }
    
    _currentSearchLocation = 1;
    DDSearchViewController *searchController = [[DDSearchViewController alloc] init];
    searchController.delegate = self;
    searchController.city = _currentLocation.cityCode;
    
    [self.navigationController pushViewController:searchController animated:YES];
}

- (void)actionCancel:(UIButton *)sender
{
    NSLog(@"actionCancel");
    [self setState:DDState_Init];
}

- (void)actionCallTaxi:(UIButton *)sender
{
    NSLog(@"actionCallTaxi");
    if (self.currentLocation && self.destinationLocation)
    {
        DDTaxiCallRequest * request = [[DDTaxiCallRequest alloc] initWithStart:self.currentLocation to:self.destinationLocation];
        [_driverManager callTaxiWithRequest:request];
        
        _messageView = [_mapView viewForMessage:@"正在呼叫司机..." title:nil image:nil];
        _messageView.center = [_mapView centerPointForPosition:@"center" withToast:_messageView];
        [_mapView addSubview:_messageView];
    }
}

- (void)actionLocating:(UIButton *)sender
{
    NSLog(@"actionLocating");
    
    // 只有初始状态下才可以进行定位。
    if (_state != DDState_Init)
    {
        [self.view makeToast:@"重新请求需先取消用车" duration:1.0 position:@"center"];
        return;
    }
    
    if (!_isLocating)
    {
        _isLocating = YES;
        
        [self resetMapToCenter:_mapView.userLocation.location.coordinate];
        [self searchReGeocodeWithCoordinate:_mapView.userLocation.location.coordinate];
        [self updatingDrivers];
    }
}

- (void)actionOnTaxi:(UIButton *)sender
{
    NSLog(@"actionOnTaxi");
    [self setState:DDState_On_Taxi];
}

- (void)actionOnPay:(UIButton *)sender
{
    NSLog(@"actionOnPay");
    [self setState:DDState_Finish_pay];
}

- (void)actionOnEvaluate:(UIButton *)sender
{
    NSLog(@"actionOnEvaluate");
    [self setState:DDState_Init];
}

#pragma mark - drivers
- (void)updatingDrivers
{
#define latitudinalRangeMeters 1000.0
#define longitudinalRangeMeters 1000.0
    
    MAMapRect rect = MAMapRectForCoordinateRegion(MACoordinateRegionMakeWithDistance(_mapView.centerCoordinate, latitudinalRangeMeters, longitudinalRangeMeters));
    [_driverManager searchDriversWithinMapRect:rect];
}

#pragma mark - driversManager delegate

- (void)searchDoneInMapRect:(MAMapRect)mapRect withDriversResult:(NSArray *)drivers timestamp:(NSTimeInterval)timestamp
{
    [_mapView removeAnnotations:_drivers];
    
    NSMutableArray * currDrivers = [NSMutableArray arrayWithCapacity:[drivers count]];
    [drivers enumerateObjectsUsingBlock:^(DDDriver * obj, NSUInteger idx, BOOL *stop) {
        MAPointAnnotation * driver = [[MAPointAnnotation alloc] init];
        driver.coordinate = obj.coordinate;
        driver.title = obj.idInfo;
        [currDrivers addObject:driver];
    }];

    [_mapView addAnnotations:currDrivers];
    
    _drivers = currDrivers;
}

- (void)callTaxiDoneWithRequest:(DDTaxiCallRequest *)request Taxi:(DDDriver *)driver
{
    [_mapView removeAnnotations:_drivers];
    
    _selectedDriver = [[MAPointAnnotation alloc] init];
    _selectedDriver.coordinate = driver.coordinate;
    _selectedDriver.title = driver.idInfo;
    [_mapView addAnnotation:_selectedDriver];
    
    [_messageView removeFromSuperview];
    [_mapView makeToast:[NSString stringWithFormat:@"已选择司机%@",driver.idInfo, nil] duration:0.5 position:@"center"];
    
    [self setState:DDState_Call_Taxi];
}

- (void)onUpdatingLocations:(NSArray *)locations forDriver:(DDDriver *)driver
{
    if ([locations count] > 0) {

        [_mapView selectAnnotation:_selectedDriver animated:NO];
        _selectedDriver.coordinate = ((CLLocation*) [locations lastObject]).coordinate;
        
        CLLocationCoordinate2D * locs = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * [locations count]);
        [locations enumerateObjectsUsingBlock:^(CLLocation * obj, NSUInteger idx, BOOL *stop) {
            locs[idx] = obj.coordinate;
        }];
        
        MovingAnnotationView * driverView = (MovingAnnotationView *)[_mapView viewForAnnotation:_selectedDriver];
        
        [driverView addTrackingAnimationForCoordinates:locs count:[locations count] duration:2.0];
        
        free(locs);
    }
}

#pragma mark - DDSearchViewControllerDelegate

- (void)searchViewController:(DDSearchViewController *)searchViewController didSelectLocation:(DDLocation *)location
{
    NSLog(@"location: %@", location);
    [self.navigationController popViewControllerAnimated:YES];
    if (_currentSearchLocation == 0)
    {
        _currentLocation = location;
        _locationView.startLocation = location;
    }
    else if (_currentSearchLocation == 1)
    {
        _destinationLocation = location;
        _locationView.endLocation = location;
    }
    _currentSearchLocation = -1;
    
    // 起点终点都确认
    if (_currentLocation && _destinationLocation)
    {
        [self setState:DDState_Confirm_Destination];
    }
}

#pragma mark - Utility

- (void)requestPathInfo
{
    //检索所需费用
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude
                                           longitude:_currentLocation.coordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:_destinationLocation.coordinate.latitude
                                                longitude:_destinationLocation.coordinate.longitude];
    
    __weak __typeof(&*self) weakSelf = self;
    [[DDSearchManager sharedInstance] searchForRequest:navi completionBlock:^(id request, id response, NSError *error) {
        
        AMapRouteSearchResponse *naviResponse = response;
        
        if (naviResponse.route == nil)
        {
            [weakSelf.locationView setInfo:@"获取路径失败"];
            return;
        }
        
        AMapPath * path = [naviResponse.route.paths firstObject];
        [weakSelf.locationView setInfo:[NSString stringWithFormat:@"预估费用%.2f元  距离%.1f km  时间%.1f分钟", naviResponse.route.taxiCost, path.distance / 1000.f, path.duration / 60.f, nil]];
    }];
}

- (void)setState:(DDState)state
{
    _state = state;
    
    switch (state)
    {
        case DDState_Init:
            [self reset];
            
            [_buttonAction setTitle:@"选择终点" forState:UIControlStateNormal];
            [_buttonAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [_buttonAction addTarget:self action:@selector(actionAddEnd:) forControlEvents:UIControlEventTouchUpInside];
            break;
            
        case DDState_Confirm_Destination:
            [self requestPathInfo];
            
            [_buttonAction setTitle:@"马上叫车" forState:UIControlStateNormal];
            [_buttonAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [_buttonAction addTarget:self action:@selector(actionCallTaxi:) forControlEvents:UIControlEventTouchUpInside];

            break;
        case DDState_Call_Taxi:
            [_buttonAction setTitle:@"我已上车" forState:UIControlStateNormal];
            [_buttonAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];

            [_buttonAction addTarget:self action:@selector(actionOnTaxi:) forControlEvents:UIControlEventTouchUpInside];

            break;
        case DDState_On_Taxi:
            [_buttonAction setTitle:@"支付" forState:UIControlStateNormal];
            [_buttonAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];

            [_buttonAction addTarget:self action:@selector(actionOnPay:) forControlEvents:UIControlEventTouchUpInside];
            break;
            
        case DDState_Finish_pay:
            [_buttonAction setTitle:@"评价" forState:UIControlStateNormal];
            [_buttonAction removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];

            [_buttonAction addTarget:self action:@selector(actionOnEvaluate:) forControlEvents:UIControlEventTouchUpInside];
            break;

        default:
            break;
    }
    
    // 设置locationView是否响应交互。
    _locationView.userInteractionEnabled = state < DDState_Call_Taxi;
    _buttonCancel.hidden = state == DDState_Init;
}

- (void)reset
{
    [_mapView removeAnnotations:_drivers];
    [_mapView removeAnnotation:_selectedDriver];
    
    _needsFirstLocating = YES;
    _destinationLocation = nil;
    _locationView.endLocation = nil;
    _locationView.info = nil;
}

- (void)resetMapToCenter:(CLLocationCoordinate2D)coordinate
{
    _mapView.centerCoordinate = coordinate;
    _mapView.zoomLevel = 15.1;
    
    // 使得userLocationView在最前。
    [_mapView selectAnnotation:_mapView.userLocation animated:YES];
}

#pragma mark - DDLocationViewDelegate

- (void)didClickStartLocation:(DDLocationView *)locationView
{
    _currentSearchLocation = 0;
    DDSearchViewController *searchController = [[DDSearchViewController alloc] init];
    searchController.delegate = self;
    searchController.text = locationView.startLocation.name;
    searchController.city = locationView.startLocation.cityCode;
    
    [self.navigationController pushViewController:searchController animated:YES];
}

- (void)didClickEndLocation:(DDLocationView *)locationView
{
    _currentSearchLocation = 1;
    DDSearchViewController *searchController = [[DDSearchViewController alloc] init];
    searchController.delegate = self;
    searchController.text = locationView.endLocation.name;
    searchController.city = locationView.endLocation.cityCode;
    
    [self.navigationController pushViewController:searchController animated:YES];
}

@end
