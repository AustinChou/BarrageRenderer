// Part of BarrageRenderer. Created by UnAsh.
// Blog: http://blog.exbye.com
// Github: https://github.com/unash/BarrageRenderer

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2015年 UnAsh.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BarrageDispatcher.h"
#import "BarrageSpirit.h"

@interface BarrageDispatcher()
{
    NSMutableArray * _activeSpirits;
    NSMutableArray * _waitingSpirits;
    NSMutableArray * _deadSpirits;
    NSDate * _startTime;
}
@end

@implementation BarrageDispatcher

- (instancetype)initWithStartTime:(NSDate *)startTime
{
    if (self = [super init]) {
        _activeSpirits = [[NSMutableArray alloc]init];
        _waitingSpirits = [[NSMutableArray alloc]init];
        _deadSpirits = [[NSMutableArray alloc]init];
        _cacheDeadSpirits = NO;
        _startTime = startTime;
    }
    return self;
}

- (void)addSpirit:(BarrageSpirit *)spirit
{
    [_waitingSpirits addObject:spirit];
}

/// 派发精灵
- (BOOL)dispatchSpiritsWithPausedDuration:(NSTimeInterval)pausedDuration
{
    BOOL statusChanged = NO;
    for (NSInteger i = 0; i < _activeSpirits.count; i ++) { // 活跃精灵队列
        BarrageSpirit * spirit = [_activeSpirits objectAtIndex:i];
        if (!spirit.isValid) {
            if (_cacheDeadSpirits) {
                [_deadSpirits addObject:spirit];
            }
            [_activeSpirits removeObjectAtIndex:i--];
            NSLog(@"%@",@"remove spirit");
            statusChanged = YES;
        }
    }
    
    NSDate * date = [NSDate date];
    static NSTimeInterval const timeWindow = 0.1f; //时间窗口, 这个值可能会影响到自动调节刷新频率的效果
    for (NSInteger i = 0; i < _waitingSpirits.count; i++) { // 等待队列
        BarrageSpirit * spirit = [_waitingSpirits objectAtIndex:i];
        NSTimeInterval overtime = [date timeIntervalSinceDate:_startTime] - pausedDuration - spirit.delay;
        if (overtime >= 0) {
            if (overtime < timeWindow) {
                [_activeSpirits addObject:spirit];
                [self activeSpirit:spirit];
                statusChanged = YES;
            }
            else
            {// 需要将过期的精灵直接放到_deadSpirits中; statusChanged并不随之变化
                if (_cacheDeadSpirits) {
                    [_deadSpirits addObject:spirit];
                }
            }
            [_waitingSpirits removeObjectAtIndex:i--];
        }
    }
    return statusChanged;
}

/// 激活精灵
- (void)activeSpirit:(BarrageSpirit *)spirit
{
    NSLog(@"%@",@"add spirit");
    if (self.delegate && [self.delegate respondsToSelector:@selector(willShowSpirit:)]) {
        [self.delegate willShowSpirit:spirit];
    }
}

#pragma mark - 属性返回
- (NSArray *)activeSpirits
{
    return [_activeSpirits copy];
}

- (NSArray *)waitingSpirits
{
    return [_waitingSpirits copy];
}

- (NSArray *)deadSpirits
{
    return [_deadSpirits copy];
}

@end