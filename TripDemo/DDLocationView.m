//
//  DDLocationView.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/2.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "DDLocationView.h"
#import "DDLocation.h"
#import "DDLocationControl.h"
#import "DDSearchManager.h"

@interface DDLocationView ()
{
    DDLocationControl *_startControl;
    DDLocationControl *_endControl;
    UILabel * _costControl;
    
    CGFloat _originHeight;
    CALayer *_lineLayer;
}
@end

@implementation DDLocationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1, 1);
        self.layer.shadowOpacity = 0.3;
        
        _originHeight = frame.size.height;
        
        _lineLayer = [CALayer layer];
        _lineLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
        _lineLayer.frame = CGRectMake(0, _originHeight, frame.size.width, 1);
        _lineLayer.hidden = YES;
        [self.layer addSublayer:_lineLayer];
        
        [self initStartControl];
    }
    
    return self;
}

- (void)dealloc
{
    if (_startLocation)
    {
        [_startLocation removeObserver:self forKeyPath:@"name"];
    }
    
    if (_endLocation)
    {
        [_endLocation removeObserver:self forKeyPath:@"name"];
    }
}

- (void)initStartControl
{
    if (!_startControl)
    {
        _startControl = [[DDLocationControl alloc] initWithFrame:self.bounds];
        [self addSubview:_startControl];
        _startControl.accessoryImage = [UIImage imageNamed:@"startPoint"];
        _startControl.title = @"定位中...";
        [_startControl addTarget:self action:@selector(actionStartClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)initEndControl
{
    if (!_endControl)
    {
        _endControl = [[DDLocationControl alloc] initWithFrame:self.bounds];
        _endControl.hidden = YES;
        [self addSubview:_endControl];
        _endControl.accessoryImage = [UIImage imageNamed:@"endPoint"];
        [_endControl addTarget:self action:@selector(actionEndClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

- (void)initCostControl
{
    if (!_costControl)
    {
        _costControl = [[UILabel alloc] initWithFrame:self.bounds];
        _costControl.hidden = YES;
        _costControl.textAlignment = NSTextAlignmentCenter;
        _costControl.textColor = [UIColor whiteColor];
        _costControl.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
        _costControl.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_costControl];
    }
}

#pragma mark - Helpers

- (void)updateStartControl
{
    if (_startLocation.name.length == 0)
    {
        _startControl.title = @"定位中...";
    }
    else
    {
        _startControl.title = _startLocation.name;
    }
}

- (void)updateEndControl
{
    [self initEndControl];
    
    if (_endLocation.name.length == 0)
    {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, _originHeight);
        _lineLayer.hidden = YES;
        _endControl.hidden = YES;
    }
    else
    {        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, _originHeight * 2 + 1);
        _lineLayer.hidden = NO;
        _endControl.hidden = NO;
        _endControl.frame = CGRectMake(0, _originHeight + 1, CGRectGetWidth(_startControl.bounds), CGRectGetHeight(_startControl.bounds));
        
        _endControl.title = _endLocation.name;
        
    }
}

- (void)updateCostControl
{
    if (_info.length > 0)
    {
        [self initCostControl];
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, _originHeight * 2.5 + 1);
        _costControl.hidden = NO;
        
        _costControl.frame = CGRectMake(0, CGRectGetHeight(_startControl.bounds) + CGRectGetHeight(_endControl.bounds) + 1, CGRectGetWidth(_startControl.bounds), CGRectGetHeight(_startControl.bounds)* 0.5f);
        
        [_costControl setText:_info];
    }
    else
    {
        CGFloat height = _endLocation.name.length ? _originHeight * 2 + 1 : _originHeight;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
        [_costControl setText:@""];
        _costControl.hidden = YES;
    }
}

#pragma mark - Public

- (void)setStartLocation:(DDLocation *)startLocation
{
    if (_startLocation == startLocation)
    {
        return;
    }
    [_startLocation removeObserver:self forKeyPath:@"name"];
    _startLocation = startLocation;
    
    [self updateStartControl];
    
    if (_startLocation)
    {
        [_startLocation addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setEndLocation:(DDLocation *)endLocation
{
    if (_endLocation == endLocation)
    {
        return;
    }
    [_endLocation removeObserver:self forKeyPath:@"name"];
    _endLocation = endLocation;

    [self updateEndControl];
    
    if (_endLocation)
    {
        [_endLocation addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setInfo:(NSString *)info
{
    _info = [info copy];
    [self updateCostControl];
}

#pragma mark - actions

- (void)actionStartClick:(UIControl *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(didClickStartLocation:)])
    {
        [_delegate didClickStartLocation:self];
    }
}

- (void)actionEndClick:(UIControl *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(didClickEndLocation:)])
    {
        [_delegate didClickEndLocation:self];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"name"])
    {
        
        if (object == _startLocation)
        {
            [self updateStartControl];
        }
        
        if (object == _endLocation)
        {
            [self updateEndControl];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
