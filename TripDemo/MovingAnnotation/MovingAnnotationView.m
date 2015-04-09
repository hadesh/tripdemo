
//
//  MovingAnnotationView.m
//  test
//
//  Created by yi chen on 14-9-3.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import "MovingAnnotationView.h"
#import "CACoordLayer.h"

#define MapXAnimationKey @"mapx"
#define MapYAnimationKey @"mapy"

@interface MovingAnnotationView()

@property (nonatomic, strong) NSMutableArray * animationList;

@end

@implementation MovingAnnotationView
{
    MAMapPoint currDestination;
    MAMapPoint lastDestination;
    
    BOOL isAnimatingX, isAnimatingY;
}

#pragma mark - Animation
+ (Class)layerClass
{
    return [CACoordLayer class];
}

- (void)addTrackingAnimationForCoordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count duration:(CFTimeInterval)duration
{
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    
    //preparing
    NSUInteger num = count + 1;
    NSMutableArray * xvalues = [NSMutableArray arrayWithCapacity:num]; NSMutableArray *yvalues = [NSMutableArray arrayWithCapacity:num];
    
    NSMutableArray * times = [NSMutableArray arrayWithCapacity:num];
    
    double sumOfDistance = 0.f;
    double * dis = malloc((count) * sizeof(double));
    
    //the first point is set by destination of last animation.
    MAMapPoint pre;
    if ([self.animationList count] > 0 || isAnimatingX || isAnimatingY)
    {
        pre = MAMapPointMake(lastDestination.x, lastDestination.y);
    }
    else
    {
        pre = MAMapPointMake(mylayer.mapx, mylayer.mapy);
    }
    
    [xvalues addObject:@(pre.x)];
    [yvalues addObject:@(pre.y)];
    [times addObject:@(0.f)];

    //set the animation points.
    for (int i = 0; i<count; i++)
    {
        MAMapPoint p = MAMapPointForCoordinate(coordinates[i]);
        [xvalues addObject:@(p.x)];
        [yvalues addObject:@(p.y)];
        
        dis[i] = MAMetersBetweenMapPoints(p, pre);
        sumOfDistance = sumOfDistance + dis[i];
        dis[i] = sumOfDistance;
        
        pre = p;
    }
    
    //set the animation times.
    for (int i = 0; i<count; i++)
    {
        [times addObject:@(dis[i]/sumOfDistance)];
    }
    
    //record the destination.
    lastDestination = MAMapPointForCoordinate(coordinates[count - 1]);
    free(dis);
    
    // add animation.
    CAKeyframeAnimation *xanimation = [CAKeyframeAnimation animationWithKeyPath:MapXAnimationKey];
    xanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    xanimation.values   = xvalues;
    xanimation.keyTimes = times;
    xanimation.duration = duration;
    xanimation.delegate = self;
    xanimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *yanimation = [CAKeyframeAnimation animationWithKeyPath:MapYAnimationKey];
    yanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    yanimation.values   = yvalues;
    yanimation.keyTimes = times;
    yanimation.duration = duration;
    yanimation.delegate = self;
    yanimation.fillMode = kCAFillModeForwards;

    
    [self pushBackAnimation:xanimation];
    [self pushBackAnimation:yanimation];
    
    mylayer.mapView = [self mapView];

}

- (void)pushBackAnimation:(CAPropertyAnimation *)anim
{
    [self.animationList addObject:anim];

    if ([self.layer animationForKey:anim.keyPath] == nil)
    {
        [self popFrontAnimationForKey:anim.keyPath];
    }
}

- (void)popFrontAnimationForKey:(NSString *)key
{
    [self.animationList enumerateObjectsUsingBlock:^(CAPropertyAnimation * obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj.keyPath isEqualToString:key])
         {
             [self.layer addAnimation:obj forKey:obj.keyPath];
             [self.animationList removeObject:obj];

             if ([key isEqualToString:MapXAnimationKey])
             {
                 isAnimatingX = YES;
             }
             else if([key isEqualToString:MapYAnimationKey])
             {
                 isAnimatingY = YES;
             }
             *stop = YES;
         }
     }];
}



#pragma mark - Animation Delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim isKindOfClass:[CAKeyframeAnimation class]])
    {
        CAKeyframeAnimation * keyAnim = ((CAKeyframeAnimation *)anim);
        if ([keyAnim.keyPath isEqualToString:MapXAnimationKey])
        {
            isAnimatingX = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapx = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.x = mylayer.mapx;
            
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapXAnimationKey];
        }
        if ([keyAnim.keyPath isEqualToString:MapYAnimationKey])
        {
            isAnimatingY = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapy = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.y = mylayer.mapy;
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapYAnimationKey];
        }

    }
}

- (void)updateAnnotationCoordinate
{
    if (! (isAnimatingX || isAnimatingY) )
    {
        self.annotation.coordinate = MACoordinateForMapPoint(currDestination);
    }
}

#pragma mark - Property

- (NSMutableArray *)animationList
{
    if (_animationList == nil)
    {
        _animationList = [NSMutableArray array];
    }
    return _animationList;
}

- (MAMapView *)mapView
{
    return (MAMapView*)(self.superview.superview);
}

#pragma mark - Override

- (void)setCenterOffset:(CGPoint)centerOffset
{
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    mylayer.centerOffset = centerOffset;
    [super setCenterOffset:centerOffset];
}

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
        MAMapPoint mapPoint = MAMapPointForCoordinate(annotation.coordinate);
        mylayer.mapx = mapPoint.x;
        mylayer.mapy = mapPoint.y;
        
        mylayer.centerOffset = self.centerOffset;
        
        isAnimatingX = NO;
        isAnimatingY = NO;
    }
    return self;
}


@end
