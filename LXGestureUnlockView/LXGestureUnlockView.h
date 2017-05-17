//
//  LXGestureUnlockView.h
//  GestureUnlock
//
//  Created by 从今以后 on 2017/5/16.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXGestureUnlockView : UIView

/// 默认 2
@property (nonatomic) IBInspectable CGFloat lineWidth;
/// 默认 8
@property (nonatomic) IBInspectable CGFloat dotRadius;
/// 默认 30
@property (nonatomic) IBInspectable CGFloat circleRadius;
/// 默认为 tintColor
@property (nonatomic) IBInspectable UIColor *lineColor;
/// 手势完成，返回密码正确性
@property (nonatomic) BOOL (^completionHandler)(NSString *password);

@end
