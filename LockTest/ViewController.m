//
//  ViewController.m
//  LockTest
//
//  Created by guazi on 2017/2/9.
//  Copyright © 2017年 guazi. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <objc/objc-sync.h>
static NSUInteger count = 100*10000;


@interface ViewController ()


@end

@implementation ViewController

- (IBAction)performanceCompare:(id)sender {
    
    CFTimeInterval timeBefore;
    CFTimeInterval timeAfter;
    NSUInteger i;
    
    //OSSpinLockLock
    OSSpinLock spinlock = OS_SPINLOCK_INIT;
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        OSSpinLockLock(&spinlock);
        OSSpinLockUnlock(&spinlock);
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"OSSpinLock used : %f\n", timeAfter-timeBefore);
    
    
    //dispatch_semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(semaphore);
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"dispatch_semaphore used : %f\n", timeAfter-timeBefore);
    

    
    //pthread_mutex
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        pthread_mutex_lock(&mutex);
        pthread_mutex_unlock(&mutex);
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"pthread_mutex used : %f\n", timeAfter-timeBefore);
    

  
    //NSLock
    NSLock *lock = [[NSLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [lock lock];
        [lock unlock];
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"NSLock used : %f\n", timeAfter-timeBefore);
    

    //5、NSCondition
    NSCondition *condition = [[NSCondition alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [condition lock];
        [condition unlock];
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"NSCondition used : %f\n", timeAfter-timeBefore);
    
    
    //NSRecursiveLock
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [recursiveLock lock];
        [recursiveLock unlock];
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"NSRecursiveLock used : %f\n", timeAfter-timeBefore);
    

    //NSConditionLock
    NSConditionLock *conditionLock = [[NSConditionLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [conditionLock lock];
        [conditionLock unlock];
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"NSConditionLock used : %f\n", timeAfter-timeBefore);
    


   
    //@synchronized
    id obj = [[NSObject alloc]init];;
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        @synchronized(obj){
        }
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"@synchronized used : %f\n", timeAfter-timeBefore);
    
    
}

- (IBAction)recursiveLock:(id)sender {

    CFTimeInterval timeBefore;
    CFTimeInterval timeAfter;
/* 递归锁*/
    //1、@synchronized
    id obj = [[NSObject alloc]init];;
    timeBefore = CFAbsoluteTimeGetCurrent();
    @synchronized(obj){
        @synchronized(obj){
            
        }
    }
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"@synchronized used : %f\n", timeAfter-timeBefore);

    
    //2、NSRecursiveLock
    NSRecursiveLock *lock = [[NSRecursiveLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    [lock lock];
    [lock lock];
    [lock unlock];
    [lock unlock];
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"NSRecursiveLock used : %f\n", timeAfter-timeBefore);
    
    
    //3、pthread_mutex
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    
    pthread_mutex_init(&mutex, &attr);
    pthread_mutexattr_destroy(&attr);
    
    timeBefore = CFAbsoluteTimeGetCurrent();
    pthread_mutex_lock(&mutex);
    pthread_mutex_lock(&mutex);
    pthread_mutex_unlock(&mutex);
    pthread_mutex_unlock(&mutex);
    timeAfter = CFAbsoluteTimeGetCurrent();
    NSLog(@"pthread_mutex used : %f\n", timeAfter-timeBefore);
    
}


- (IBAction)spinlock:(id)sender {
    NSLog(@"*************  spinlock  **********");

    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    
    CFTimeInterval timeBefore;
   __block CFTimeInterval timeAfter;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    timeBefore = CFAbsoluteTimeGetCurrent();

    
    //线程1
    dispatch_group_async(group, queue, ^{
        OSSpinLockLock(&spinlock);
        [self thread1];
        sleep(5);
        //此时，线程2的线程 正在试图获取锁，其他线程的锁都在自旋。
        OSSpinLockUnlock(&spinlock);
    });
   


    for (int i=0; i<10; i++) {
        //线程2
        dispatch_group_async(group, queue, ^{

            OSSpinLockLock(&spinlock);
            [self thread2];
            OSSpinLockUnlock(&spinlock);
        });
    }

    
    dispatch_group_notify(group, queue, ^{
        timeAfter = CFAbsoluteTimeGetCurrent();
        NSLog(@"spinlock used : %f\n\n\n\n", timeAfter-timeBefore);
    });

}
- (void)thread1
{

    NSLog(@"---- thread1");
}

- (void)thread2
{
    NSLog(@"---- thread2");
}

- (IBAction)mutexLock:(id)sender {
    NSLog(@"*************  mutexLock  **********");

    __block NSLock *lock = [[NSLock alloc]init];

    CFTimeInterval timeBefore;
    __block CFTimeInterval timeAfter;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    timeBefore = CFAbsoluteTimeGetCurrent();
    
    //线程1
    dispatch_group_async(group, queue, ^{
        [lock lock];
        [self thread1];
        sleep(5);
        [lock unlock];
    });
    
    
    for (int i=0; i<10; i++) {
        //线程2
        dispatch_group_async(group, queue, ^{
            [lock lock];
            [self thread2];
            [lock unlock];
        });
    }
    
    dispatch_group_notify(group, queue, ^{
        timeAfter = CFAbsoluteTimeGetCurrent();
        NSLog(@"mutexLock used : %f\n\n\n\n", timeAfter-timeBefore);
    });

}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
