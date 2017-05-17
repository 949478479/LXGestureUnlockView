//
//  LXGestureUnlockView.m
//  GestureUnlock
//
//  Created by 从今以后 on 2017/5/16.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "LXGestureUnlockView.h"

@interface LXLocationLayer : CALayer
@property (nonatomic) NSUInteger digit;
@property (nonatomic) CGFloat dotRadius;
@property (nonatomic) CGFloat circleRadius;
@property (nonatomic, readonly) CALayer *dotLayer;
@property (nonatomic, getter=isSelected) BOOL selected;
@end

@implementation LXLocationLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSublayer:({
            _dotLayer = [CALayer new];
            _dotLayer.hidden = YES;
            _dotLayer.actions = @{ @"hidden" : [NSNull null], @"backgroundColor" : [NSNull null] };
            _dotLayer;
        })];
        self.borderWidth = 1;
    }
    return self;
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    return nil;
}

- (void)layoutSublayers
{
    self.dotLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)setDotRadius:(CGFloat)dotRadius
{
    _dotRadius = dotRadius;
    
    self.dotLayer.cornerRadius = dotRadius;
    self.dotLayer.bounds = CGRectMake(0, 0, dotRadius * 2, dotRadius * 2);
}

- (void)setCircleRadius:(CGFloat)circleRadius
{
    _circleRadius = circleRadius;
    
    self.cornerRadius = circleRadius;
    self.bounds = CGRectMake(0, 0, circleRadius * 2, circleRadius * 2);
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;

    self.dotLayer.hidden = !selected;
}

@end


@protocol LXRenderLayerDelegate <NSObject>
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
@end

@interface LXRenderLayer : CALayer
@property (nonatomic, unsafe_unretained) id<LXRenderLayerDelegate> _delegate;
@end

@implementation LXRenderLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
    }
    return self;
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    return nil;
}

- (void)drawInContext:(CGContextRef)ctx
{
    [self._delegate drawLayer:self inContext:ctx];
}

@end


@interface LXGestureUnlockView () <LXRenderLayerDelegate>

@property (nonatomic) LXRenderLayer *renderLayer;

@property (nonatomic) CGPoint currentPoint;
@property (nonatomic) CGMutablePathRef path;
@property (nonatomic) UIColor *lineColorBackup;
@property (nonatomic) NSArray<LXLocationLayer *> *locationLayers;
@property (nonatomic) NSMutableArray<LXLocationLayer *> *selectedLocationLayers;

@end

@implementation LXGestureUnlockView

- (void)dealloc
{
    CGPathRelease(_path);
}

#pragma mark - 初始化

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    NSMutableArray *locationLayers = [NSMutableArray arrayWithCapacity:9];
    _selectedLocationLayers = [locationLayers mutableCopy];
    for (int i = 0; i < 9; ++i) {
        LXLocationLayer *layer = [LXLocationLayer new];
        layer.digit = i;
        [self.layer addSublayer:layer];
        [locationLayers addObject:layer];
    }
    _locationLayers = locationLayers;
    
    _renderLayer = [LXRenderLayer new];
    _renderLayer._delegate = self;
    [self.layer addSublayer:_renderLayer];
    
    [self _setTintColor];
    
    _lineWidth = 2;
    self.dotRadius = 8;
    self.circleRadius = 30;
}

#pragma mark - 布局

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    self.renderLayer.frame = self.bounds;
    
    CGFloat margin = 20;
    CGFloat padding = (CGRectGetWidth(self.bounds) - 2 * margin - 3 * self.circleRadius * 2) / 2;
    CGFloat radius = self.circleRadius;
    [self.locationLayers enumerateObjectsUsingBlock:^(LXLocationLayer *layer, NSUInteger idx, BOOL *stop) {
        int row = (int)idx / 3;
        int col = (int)idx % 3;
        CGPoint position = {
            margin + radius * (2 * col + 1) + padding * col,
            margin + radius * (2 * row + 1) + padding * row,
        };
        layer.position = position;
    }];
}

#pragma mark - 颜色

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    [self _setTintColor];
}

- (void)_setTintColor
{
    CGColorRef tintColorRef = self.tintColor.CGColor;
    for (LXLocationLayer *layer in self.locationLayers) {
        layer.borderColor = tintColorRef;
        layer.dotLayer.backgroundColor = tintColorRef;
    }
}

- (void)_setColorWhenFailure
{
    UIColor *redColor = [UIColor redColor];
    CGColorRef redColorRef = redColor.CGColor;
    
    self.lineColorBackup = _lineColor;
    self.lineColor = redColor;
    for (LXLocationLayer *layer in self.selectedLocationLayers) {
        layer.borderColor = redColorRef;
        layer.dotLayer.backgroundColor = redColorRef;
    }
}

- (void)_resetColorAfterFailure
{
    [self _setTintColor];
    
    self.lineColor = self.lineColorBackup;
}

- (UIColor *)lineColor
{
    if (_lineColor) {
        return _lineColor;
    }
    return self.tintColor;
}

#pragma mark - 尺寸

- (void)setDotRadius:(CGFloat)dotRadius
{
    _dotRadius = dotRadius;
    
    for (LXLocationLayer *layer in self.locationLayers) {
        layer.dotRadius = dotRadius;
    }
}

- (void)setCircleRadius:(CGFloat)circleRadius
{
    _circleRadius = circleRadius;
    
    for (LXLocationLayer *layer in self.locationLayers) {
        layer.circleRadius = circleRadius;
    }
}

#pragma mark - 触摸

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleTouchesBeganAndMoved:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleTouchesBeganAndMoved:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleTouchesEndedOrCancelled:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleTouchesEndedOrCancelled:touches];
}

- (void)_handleTouchesBeganAndMoved:(NSSet *)touches
{
    UITouch *touch = touches.anyObject;
    
    CGPoint point1 = self.currentPoint, point2, point3;
    self.currentPoint = [touch locationInView:self];
    
    LXLocationLayer *layer  = [self _layerForPoint:self.currentPoint];
    
    if (layer && !layer.isSelected) {
        // 如果连接到新点位,根据当前触摸点 point1，新点位 point2，之前末尾点位 point3 计算重绘矩形范围
        point2 = layer.position;
        point3 = [self.selectedLocationLayers.lastObject position];
        point3 = CGPointEqualToPoint(point3, CGPointZero) ? point2 : point3;
        
        [self _selectLayer:layer];
        [self _initPathIfNeeded];
        [self _addLocationToPath:layer.position];
    }
    else if (!CGPathIsEmpty(self.path)) {
        // 如果未连接到新点位，根据上一触摸点 point1，当前触摸点 point2，末尾点位 point3 计算重绘矩形范围
        point2 = self.currentPoint;
        point3 = [self.selectedLocationLayers.lastObject position];
    }
    else {
        // 该次手势移动没有选中任何点位，并且路径也是空的，不绘制任何线条
        return;
    }
    
    CGRect dirtyRect = [self _dirtyRectForPoint1:point1
                                          point2:point2
                                          point3:point3
                                       lineWidth:self.lineWidth];
    [self.renderLayer setNeedsDisplayInRect:dirtyRect];
}

- (void)_handleTouchesEndedOrCancelled:(NSSet *)touches
{
    if (!self.path || CGPathIsEmpty(self.path)) {
        return;
    }
 
    // 避免将松手时的触摸点绘制进去，否则会导致一根线连到外面
    self.currentPoint = CGPathGetCurrentPoint(self.path);
    
    if (![self _verifyPassword]) {
        [self _setColorWhenFailure];
    }
    
    [self.renderLayer setNeedsDisplay];
    
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
        [self _clearLines];
        [self _clearLocations];
        [self _resetColorAfterFailure];
    });
}

#pragma mark - 渲染

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (!self.path || CGPathIsEmpty(self.path)) {
        return;
    }
    
    CGContextAddPath(ctx, self.path);
    CGContextAddLineToPoint(ctx, self.currentPoint.x, self.currentPoint.y);
    
    CGContextSetLineWidth(ctx, self.lineWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(ctx, self.lineColor.CGColor);
    
    CGContextStrokePath(ctx);
}

#pragma mark - 重置

- (void)_clearLines
{
    CGPathRelease(self.path);
    self.path = NULL;
    [self.renderLayer setNeedsDisplay];
}

- (void)_clearLocations
{
    [self.selectedLocationLayers makeObjectsPerformSelector:@selector(setSelected:) withObject:@(NO)];
    [self.selectedLocationLayers removeAllObjects];
}

#pragma mark -  验证

- (BOOL)_verifyPassword
{
    NSMutableString *password = [NSMutableString stringWithCapacity:9];
    for (LXLocationLayer *layer in self.selectedLocationLayers) {
        [password appendFormat:@"%u", (unsigned)layer.digit];
    }
    return self.completionHandler ? self.completionHandler(password) : NO;
}

#pragma mark - helper

- (LXLocationLayer *)_layerForPoint:(CGPoint)point
{
    for (LXLocationLayer *layer in self.locationLayers) {
        if (CGRectContainsPoint(layer.frame, point)) {
            return layer;
        }
    }
    return nil;
}

- (void)_selectLayer:(LXLocationLayer *)layer
{
    layer.selected = YES;
    [self.selectedLocationLayers addObject:layer];
}

- (void)_initPathIfNeeded
{
    if (!self.path) {
        self.path = CGPathCreateMutable();
    }
}

- (void)_addLocationToPath:(CGPoint)location
{
    if (CGPathIsEmpty(self.path)) {
        CGPathMoveToPoint(self.path, NULL, location.x, location.y);
    } else {
        CGPathAddLineToPoint(self.path, NULL, location.x, location.y);
    }
}

- (CGRect)_dirtyRectForPoint1:(CGPoint)point1
                       point2:(CGPoint)point2
                       point3:(CGPoint)point3
                    lineWidth:(CGFloat)lineWidth
{
    CGFloat minX = fmin(fmin(point1.x, point2.x), point3.x) - lineWidth / 2;
    CGFloat minY = fmin(fmin(point1.y, point2.y), point3.y) - lineWidth / 2;
    CGFloat maxX = fmax(fmax(point1.x, point2.x), point3.x) + lineWidth / 2;
    CGFloat maxY = fmax(fmax(point1.y, point2.y), point3.y) + lineWidth / 2;
    
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

@end
