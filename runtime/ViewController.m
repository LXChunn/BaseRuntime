//
//  ViewController.m
//  runtime
//
//  Created by 刘小椿 on 16/5/13.
//  Copyright © 2016年 刘小椿. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "NSMutableArray+Extension.h"
#import <objc/message.h>

@interface CustomClass : NSObject

@property (nonatomic,strong)NSString* name;
@property (nonatomic,strong)NSArray* grades;
@property (nonatomic,strong)NSNumber* number;
@property (nonatomic,assign)CGFloat height;
@property (nonatomic,assign)CGFloat hhhh;

- (void)fun1;

@end



@implementation CustomClass

void abc(id self, SEL _cmd){
    NSLog(@"%@说了hello", [self name]);
}

+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (sel == @selector(doSomething)) {
        class_addMethod([self class], sel, (IMP)abc, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
    Class class = NSClassFromString(@"secondViewController");
    UIViewController* vc = class.new;
    if (aSelector == NSSelectorFromString(@"abc")) {
        return vc;
    }
    return nil;
}

- (void)fun1
{
    [self performSelector:@selector(doSomething)];
}

@end


@interface ViewController ()

@property (nonatomic,strong)NSMutableArray* arrayI;
@property (nonatomic,strong)NSDictionary* dictionary;
@property (nonatomic,strong)NSMutableArray* arrayM;

@end

static void printSchool(id self, SEL _cmd)
{
    NSLog(@"我的学校");
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.动态的遍历一个类的所有成员变量
    unsigned int count = 0;
    /** Ivar:表示成员变量类型 */
    Ivar* ivars = class_copyIvarList([CustomClass class], &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char* name = ivar_getName(ivar);
        NSString* key = [NSString stringWithUTF8String:name];
        NSLog(@"%d -- %@ -- %s",i,key,ivar_getTypeEncoding(ivar));
    }
    
    //2.获取一个类的全部属性
    unsigned int count2 = 0;
    //获取指向该类所有属性的指针
    objc_property_t* properties = class_copyPropertyList([CustomClass class], &count2);
    for (int i =0; i < count2; i++) {
        //根据objc_property_t获取其属性的名称
        const char* property = property_getName(properties[i]);
        
        NSString* key = [NSString stringWithUTF8String:property];
        NSLog(@"属性 %d -- %@",i,key);
    }
    
    //3.交换方法
    [self.arrayI addObject:@"AAA"];
    [self.arrayI addObject:@"BBB"];
    [self.arrayI addObject:nil];
    NSLog(@"%@",self.arrayI);
    
    //4.字典转模型
    unsigned int countD = 0;
    CustomClass* person = [CustomClass new];
    Ivar* vars = class_copyIvarList([CustomClass class], &countD);
    
    for (int i = 0; i < countD; i++) {
        const char* cname = ivar_getName(vars[i]);
        NSString* name = [NSString stringWithUTF8String:cname];
        NSString* key = [name substringFromIndex:1];//去掉‘_’
        NSLog(@"key = %@",key);
        if (![self filteDictionary:key]) {
            [person setValue:@"" forKey:key];
        }else{
            [person setValue:self.dictionary[key] forKey:key];
        }
    }
    NSLog(@"%@",person);
    //5.关联
    
    /*objc_setAssociatedObject方法的参数解释:
    第一个参数id object, 当前对象
    第二个参数const void *key, 关联的key，是c字符串
    第三个参数id value, 被关联的对象
    第四个参数objc_AssociationPolicy policy关联引用的规则，取值有以下几种：
    enum {
        OBJC_ASSOCIATION_ASSIGN = 0,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
        OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
        OBJC_ASSOCIATION_RETAIN = 01401,
        OBJC_ASSOCIATION_COPY = 01403
    };*/
    const char* propertiesKey = "propertiesKey";
    objc_setAssociatedObject(self, propertiesKey, self.arrayI, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    NSArray *pList = objc_getAssociatedObject(self, propertiesKey);
    NSLog(@"%@",pList);
    
    //6.(消息转发机制)
    [person fun1];
    // Do any additional setup after loading the view, typically from a nib.
}

//7.添加成员变量 方法
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    Class classStudent = objc_allocateClassPair([CustomClass class], "Student", 0);
    
    // 添加一个NSString的变量，第四个参数是对其方式，第五个参数是参数类型
    if (class_addIvar(classStudent, "schoolName", sizeof(NSString *), 0, "@")) {
        NSLog(@"添加成员变量schoolName成功");
    }
    
    // 为Student类添加方法 "v@:"这种写法见参数类型连接
    if (class_addMethod(classStudent, @selector(printSchool), (IMP)printSchool, "v@:")) {
        NSLog(@"添加方法printSchool:成功");
    }
    
    // 注册这个类到runtime系统中就可以使用他了
    objc_registerClassPair(classStudent); // 返回void
    
    // 使用创建的类
    id student = [[classStudent alloc] init];
    NSString *schoolName = @"清华大学";
    // 给刚刚添加的变量赋值
    // object_setInstanceVariable(student, "schoolName", (void *)&str);在ARC下不允许使用
    [student setValue:schoolName forKey:@"schoolName"];
    
    //动态的遍历一个类的所有成员变量
    unsigned int count = 0;
    /** Ivar:表示成员变量类型 */
    Ivar* ivars = class_copyIvarList(classStudent, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char* name = ivar_getName(ivar);
        NSString* key = [NSString stringWithUTF8String:name];
        NSLog(@"%d -- %@",i,key);
    }
    
    // 调用printSchool方法，也就是给student这个接受者发送printSchool:这个消息
    //    objc_msgSend(student, "printSchool"); // 我尝试用这种方法调用但是没有成功
    [student performSelector:@selector(printSchool) withObject:nil]; // 动态调用未显式在类中声明的方法
}

- (BOOL)filteDictionary:(NSString *)key
{
    for (NSString* string in [self.dictionary allKeys]) {
        if ([string isEqual:key]) {
            return YES;
        }
    }
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableArray *)arrayI
{
    if (!_arrayI) {
        _arrayI = [NSMutableArray array];
    }
    return _arrayI;
}

- (NSDictionary *)dictionary
{
    if (!_dictionary) {
        _dictionary = @{@"name":@"liuxiaochun",
                        @"grades":@[@"AA",@"BB",@"CC",@"DD"],
                        @"number":@55,
                        @"height":@175
                        };
    }
    return _dictionary;
}
- (NSMutableArray *)arrayM
{
    if (!_arrayM) {
        _arrayM = [NSMutableArray array];
    }
    return _arrayM;
}


@end
