//
//  ViewController.m
//  GestureUnlock
//
//  Created by 从今以后 on 2017/5/16.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "ViewController.h"
#import "LXGestureUnlockView.h"

@interface ViewController ()
@property (nonatomic) BOOL didSetPassword;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) IBOutlet UILabel *tipsLabel;
@property (nonatomic) IBOutlet LXGestureUnlockView *unlockView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    self.unlockView.completionHandler = ^BOOL(NSString *password) {
        __strong typeof(weakSelf) self = weakSelf;
        
        NSLog(@"password: %@", password);
        
        if (!self.password) {
            self.password = password;
            self.tipsLabel.text = @"请再次勾画解锁图案以确认";
            return YES;
        }
        
        if (self.didSetPassword) {
            return [self.password isEqualToString:password];
        }
        
        if ([self.password isEqualToString:password]) {
            self.didSetPassword = YES;
            self.tipsLabel.text = @"解锁图案设置成功，可以测试了";
            return YES;
        }
        
        self.password = nil;
        self.tipsLabel.text = @"两次解锁图案不一致，请重新勾画";
        return NO;
    };
}

- (IBAction)reset
{
    self.password = nil;
    self.didSetPassword = NO;
    self.tipsLabel.text = @"请勾画解锁图案";
}

@end
