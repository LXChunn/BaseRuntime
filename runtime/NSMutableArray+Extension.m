//
//  NSMutableArray+Extension.m
//  runtime
//
//  Created by 刘小椿 on 16/5/13.
//  Copyright © 2016年 刘小椿. All rights reserved.
//

#import "NSMutableArray+Extension.h"
#import <objc/runtime.h>

@implementation NSMutableArray (Extension)

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(addObject:));
    Method newMethod = class_getInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(gp_addObject:));
    //交换方法
    method_exchangeImplementations(originalMethod, newMethod);
}

- (void)gp_addObject:(id)object
{
    if (object) {
        [self gp_addObject:object];
    }
}

@end
