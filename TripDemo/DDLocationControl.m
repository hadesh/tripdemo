//
//  DDLocationControl.m
//  TripDemo
//
//  Created by xiaoming han on 15/4/3.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "DDLocationControl.h"

#define kDefaultAccessoryViewSize       32
#define kDefaultAccessoryViewMargin     5

@interface DDLocationControl ()
{
    UILabel *_titleLabel;
    UIImageView *_leftAccessoryView;
    UIImageView *_rightAccessoryView;
    
    CALayer *_highLightLayer;
}

@end
@implementation DDLocationControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        _highLightLayer = [CALayer layer];
        _highLightLayer.frame = self.bounds;
        _highLightLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_highLightLayer];
        
        _leftAccessoryView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _rightAccessoryView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _rightAccessoryView.alpha = 0.4;
        _rightAccessoryView.image = [UIImage imageNamed:@"icon_next"];
        
        [self addSubview:_leftAccessoryView];
        [self addSubview:_rightAccessoryView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    _highLightLayer.frame = self.bounds;
    
    CGFloat accessoryViewSize = kDefaultAccessoryViewSize > CGRectGetHeight(self.bounds) ? CGRectGetHeight(self.bounds) : kDefaultAccessoryViewSize;
 
    CGFloat accessoryViewY = (CGRectGetHeight(self.bounds) - kDefaultAccessoryViewSize) / 2.0;
    
    _leftAccessoryView.frame = CGRectMake(kDefaultAccessoryViewMargin, accessoryViewY, accessoryViewSize, accessoryViewSize);
    
    _titleLabel.frame = CGRectMake(accessoryViewSize + kDefaultAccessoryViewMargin * 2, 0, CGRectGetWidth(self.bounds) - (accessoryViewSize + kDefaultAccessoryViewMargin) * 2, CGRectGetHeight(self.bounds));
    
    _rightAccessoryView.frame = CGRectMake(CGRectGetMaxX(_titleLabel.frame) + kDefaultAccessoryViewMargin, (CGRectGetHeight(self.bounds) - _rightAccessoryView.image.size.height) / 2.0, _rightAccessoryView.image.size.width, _rightAccessoryView.image.size.height);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted)
    {
        _highLightLayer.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.4].CGColor;
    }
    else
    {
        _highLightLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
}

#pragma mark - 

- (void)setAccessoryImage:(UIImage *)accessoryImage
{
    if (_leftAccessoryView.image == accessoryImage)
    {
        return;
    }
    
    _leftAccessoryView.image = accessoryImage;
}

- (UIImage *)accessoryImage
{
    return _leftAccessoryView.image;
}

- (NSString *)title
{
    return _titleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
