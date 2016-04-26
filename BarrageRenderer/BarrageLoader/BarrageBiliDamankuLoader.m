//
//  BarrageBiliDamankuLoader.m
//  Pods
//
//  Created by Yifei Zhou on 4/25/16.
//
//

#import "BarrageBiliDamankuLoader.h"
#import <ALDKit/ALDKit.h>

// https://github.com/Bilibili/DanmakuFlameMaster/wiki/常见问题

// <d p="23.826000213623,1,25,16777215,1422201084,0,057075e9,757076900">我从未见过如此厚颜无耻之猴</d>
// 0:时间(弹幕出现时间)
// 1:类型(1从左至右滚动弹幕|6从右至左滚动弹幕|5顶端固定弹幕|4底端固定弹幕|7高级弹幕|8脚本弹幕)
// 2:字号
// 3:颜色
// 4:时间戳 ?
// 5:弹幕池id
// 6:用户hash
// 7:弹幕id

@implementation BarrageBiliDamankuLoader

+ (NSArray *)readDescriptorsWithFile:(NSString *)file
{
    return [self readDescriptorsWithFile:file options:kNilOptions];
}

+ (NSArray *)readDescriptorsWithFile:(NSString *)file options:(NSDataReadingOptions)options
{
    if (!file || [file isEqualToString:@""])
        return nil;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:file])
        return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:file options:options error:nil];
    if (!data) {
        return nil;
    }
    
    NSString *danmakuContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *pattern = @"<d\\s?p=\\\"(.+)\\\">(.+)<\\/d>";
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSMutableArray *descriptors = [@[] mutableCopy];
    
    [[danmakuContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@""])
            return;
        NSTextCheckingResult *match = [regex firstMatchInString:obj options:0 range:NSMakeRange(0, obj.length)];
        if ([match numberOfRanges] < 3)
            return;
        
        NSString *parameters = [obj substringWithRange:[match rangeAtIndex:1]];
        NSString *text = [obj substringWithRange:[match rangeAtIndex:2]];
        
        [descriptors addObject:[self createDescriptorWithParameters:parameters text:text]];
    }];
    
    return [NSArray arrayWithArray:descriptors];
}

+ (nonnull BarrageDescriptor *)createDescriptorWithParameters:(NSString *)parameters text:(NSString *)text
{
    NSParameterAssert(parameters != nil);
    NSParameterAssert(text != nil);
    
    NSArray *components = [parameters componentsSeparatedByString:@","];
    
    NSAssert(components.count == 8, @"Malformed bilibili damanku format!");

    NSNumber *beginTime = [NSNumber numberWithString:components[0]];
    NSNumber *damankuType = [NSNumber numberWithString:components[1]];
    NSNumber *fontSize = [NSNumber numberWithString:components[2]];
    NSString *fontColorDecString = [components[3] copy];
    NSNumber *timestamp = [NSNumber numberWithString:components[4]];
    NSNumber *damankuPoolID = [NSNumber numberWithString:components[5]];
    NSString *userHash = [components[6] copy];
    NSNumber *damankuID = [NSNumber numberWithString:components[7]];

    BarrageDescriptor *descriptor = [[BarrageDescriptor alloc] init];
    descriptor.params[@"text"] = text;
    descriptor.params[@"textColor"] = [UIColor colorWithHexString:[NSString hexStringWithDecimalString:fontColorDecString]];
    descriptor.params[@"fontSize"] = fontSize;
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"delay"] = @([beginTime floatValue]);

    /*
     typedef NS_ENUM(NSUInteger, BarrageWalkDirection) {
         BarrageWalkDirectionR2L = 1,  // 右向左
         BarrageWalkDirectionL2R = 2,  // 左向右
         BarrageWalkDirectionT2B = 3,  // 上往下
         BarrageWalkDirectionB2T = 4   // 下往上
     };
     typedef NS_ENUM(NSUInteger, BarrageFloatDirection) {
         BarrageFloatDirectionT2B = 1,     // 上往下
         BarrageFloatDirectionB2T = 2      // 下往上
     };
    */
    
    if ([damankuType unsignedIntegerValue] == 1) {
        descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
        descriptor.params[@"direction"] = @(BarrageWalkDirectionR2L);
    } else if ([damankuType unsignedIntegerValue] == 6) {
        descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
        descriptor.params[@"direction"] = @(BarrageWalkDirectionL2R);
    } else if ([damankuType unsignedIntegerValue] == 5) {
        descriptor.spriteName = NSStringFromClass([BarrageFloatTextSprite class]);
        descriptor.params[@"direction"] = @(BarrageWalkDirectionT2B);
    } else if ([damankuType unsignedIntegerValue] == 4) {
        descriptor.spriteName = NSStringFromClass([BarrageFloatTextSprite class]);
        descriptor.params[@"direction"] = @(BarrageWalkDirectionB2T);
    }
    return descriptor;
}

@end
