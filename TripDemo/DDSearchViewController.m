//
//  DDSearchViewController.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/3.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "DDSearchViewController.h"
#import "DDLocation.h"
#import "DDSearchManager.h"

@interface DDSearchViewController ()<UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *displayController;
@property (nonatomic, strong) NSMutableArray *locations;

@end

@implementation DDSearchViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _text = @"";
        _city = @"";
        _locations = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initSearchBar];
    [self initSearchDisplay];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_searchBar becomeFirstResponder];
    if (self.text.length > 0)
    {
        [self searchTipsWithKey:self.text];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

#pragma mark - Initialization

- (void)initSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    self.searchBar.barStyle     = UIBarStyleBlack;
    self.searchBar.translucent  = YES;
    self.searchBar.delegate     = self;
    self.searchBar.placeholder = @"搜索";
    self.searchBar.text = self.text;
    self.searchBar.keyboardType = UIKeyboardTypeDefault;
    
    self.navigationItem.titleView = self.searchBar;
}

- (void)initSearchDisplay
{
    self.displayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.displayController.delegate                = self;
    self.displayController.searchResultsDataSource = self;
    self.displayController.searchResultsDelegate   = self;
    self.displayController.displaysSearchBarInNavigationBar = YES;
}

#pragma mark - Helpers

- (void)searchTipsWithKey:(NSString *)key
{
    if (key.length == 0)
    {
        return;
    }

    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    request.requireExtension = YES;
    request.searchType = AMapSearchType_PlaceKeyword;
    request.keywords = key;
    
    if (self.city.length > 0)
    {
        request.city = @[self.city];
    }
    
    __weak __typeof(&*self) weakSelf = self;
    [[DDSearchManager sharedInstance] searchForRequest:request completionBlock:^(id request, id response, NSError *error) {
        if (error)
        {
            NSLog(@"error :%@", error);
        }
        else
        {
            [weakSelf.locations removeAllObjects];
            
            AMapPlaceSearchResponse *aResponse = (AMapPlaceSearchResponse *)response;
            [aResponse.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop)
             {
                 DDLocation *location = [[DDLocation alloc] init];
                 location.name = obj.name;
                 location.coordinate = CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude);
                 location.address = obj.address;
                 location.cityCode = obj.citycode;
                 [weakSelf.locations addObject:location];
             }];
            
            [weakSelf.displayController.searchResultsTableView reloadData];
        }
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.text = searchBar.text;
    [self searchTipsWithKey:self.text];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.text = searchString;
    [self searchTipsWithKey:self.text];
    
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.locations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    }
    
    DDLocation *location = self.locations[indexPath.row];
    
    cell.textLabel.text = location.name;
    cell.detailTextLabel.text = location.address;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_searchBar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    DDLocation *location = self.locations[indexPath.row];
    if (_delegate && [_delegate respondsToSelector:@selector(searchViewController:didSelectLocation:)])
    {
        [_delegate searchViewController:self didSelectLocation:location];
    }
}

@end
