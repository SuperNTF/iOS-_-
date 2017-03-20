//
//  TestViewController.m
//  LockTest
//
//  Created by super_N on 17/3/13.
//  Copyright © 2017年 guazi. All rights reserved.
//

#import "TestViewController.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <objc/objc-sync.h>

#define MAX_COUNT 2

@implementation TestViewController

//互斥锁
//1、
- (IBAction)nslock:(id)sender {
    NSLog(@"\n\n***********************");

    NSLock *lock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        NSLog(@"线程1");
        sleep(2);
        [lock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        NSLog(@"线程2");
        [lock unlock];
    });

}

//2、
static pthread_mutex_t theLock;

- (IBAction)pthread_mutex:(id)sender {
    
    pthread_mutex_init(&theLock, NULL);
    
    pthread_t thread1,thread2;
    
    pthread_create(&thread1, NULL, threadMethord1, NULL);

    pthread_create(&thread2, NULL, threadMethord2, NULL);
    
    pthread_join(thread1,NULL);
    pthread_join(thread2,NULL);
}

void *threadMethord1() {
    pthread_mutex_lock(&theLock);
    printf("线程1\n");
    sleep(1);
    pthread_mutex_unlock(&theLock);
    printf("线程1解锁成功\n");
    return 0;
}

void *threadMethord2() {
    pthread_mutex_lock(&theLock);
    printf("线程2\n");
    sleep(1);
    pthread_mutex_unlock(&theLock);
    printf("线程2解锁成功\n");
    return 0;
}

//3、
- (IBAction)synchronized:(id)sender {
    NSLog(@"\n\n***********************");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            sleep(2);
            NSLog(@"线程1");
        }
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            NSLog(@"线程2");
        }
    });
    

}



- (IBAction)conditionLock:(id)sender {
    NSLog(@"\n\n***********************");
    
    
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lockWhenCondition:1];
        NSLog(@"线程1");
        sleep(2);
        [lock unlock];
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);//以保证让线程2的代码后执行
        if ([lock tryLockWhenCondition:0]) {
            NSLog(@"线程2");
            [lock unlockWithCondition:2];
            NSLog(@"线程2解锁成功");
        } else {
            NSLog(@"线程2尝试加锁失败");
        }
    });
    
    //线程3
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);//以保证让线程2的代码后执行
        if ([lock tryLockWhenCondition:2]) {
            NSLog(@"线程3");
            [lock unlock];
            NSLog(@"线程3解锁成功");
        } else {
            NSLog(@"线程3尝试加锁失败");
        }
    });
    
    //线程4
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(3);//以保证让线程2的代码后执行
        if ([lock tryLockWhenCondition:2]) {
            NSLog(@"线程4");
            [lock unlockWithCondition:1];
            NSLog(@"线程4解锁成功");
        } else {
            NSLog(@"线程4尝试加锁失败");
        }
    });
    
}
//递归锁
static void (^RecursiveBlock)(int);
#define RecursiveType 1
- (IBAction)recursiveLock:(id)sender {
    NSLog(@"\n\n***********************");

    switch (RecursiveType) {
        case 1:
        {
            NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                RecursiveBlock = ^(int value) {
                    [lock lock];
                    if (value > 0) {
                        NSLog(@"value:%d", value);
                        RecursiveBlock(value - 1);
                    }
                    [lock unlock];
                };
                RecursiveBlock(2);
            });
        }
            break;
        default:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RecursiveBlock = ^(int value) {
                    @synchronized (self) {
                        if (value > 0) {
                            NSLog(@"value:%d", value);
                            RecursiveBlock(value - 1);
                        }
                    }
                };
                RecursiveBlock(2);
            });
        }
            break;
    }
    

    
}



//自旋锁
- (IBAction)spinLock:(id)sender {
    NSLog(@"\n\n***********************");

    
    __block CFTimeInterval timeBefore;
    __block CFTimeInterval timeAfter;
    
    __block OSSpinLock theLock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        timeBefore = CFAbsoluteTimeGetCurrent();
        OSSpinLockLock(&theLock);
        NSLog(@"线程1");
        sleep(10);
        OSSpinLockUnlock(&theLock);
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        OSSpinLockLock(&theLock);
        NSLog(@"线程2");
        sleep(3);
        NSLog(@"线程2解锁成功");
        OSSpinLockUnlock(&theLock);
        timeAfter = CFAbsoluteTimeGetCurrent();
        NSLog(@"spinlock used : %f\n\n\n\n", timeAfter-timeBefore);

    });
    

}

unsigned count = 0;

//条件锁
- (IBAction)condition:(id)sender {
    NSLog(@"\n\n***********************");

    count = 0;
    
    NSCondition *lock = [[NSCondition alloc] init];
    //线程1
    for (int i = 0 ; i < MAX_COUNT; i ++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [lock lock];
            NSLog(@" ---- 线程1");

            while (!count) {
                [lock wait];
            }
            NSLog(@"-----线程1 index -- : %d",count);

            sleep(3);
            count--;
            NSLog(@"-----线程1 index -- : %d over",count+1);

            [lock unlock];
        });
    }
 
    for (int i = 0 ; i < MAX_COUNT; i ++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [lock lock];
            NSLog(@" **** 线程2");
            NSLog(@"*****线程2 index --: %d",count+1);
            sleep(1);
            count++;
            NSLog(@"-----线程2 index -- : %d over",count);

            [lock signal];
            [lock unlock];
        });

    }
 

}


pthread_mutex_t p_lock;
pthread_cond_t p_cond;

- (IBAction)posix_condition:(id)sender {
    count = 0;
    pthread_t tid1[MAX_COUNT], tid2[MAX_COUNT];
    
    pthread_mutex_init(&p_lock, NULL);
    pthread_cond_init(&p_cond, NULL);
    
    for (int i = 0 ; i < MAX_COUNT; i++) {
        pthread_create(&tid1[i], NULL, decrement_count, NULL);
        pthread_create(&tid2[i], NULL, increment_count, NULL);
        
        pthread_join(tid1[i],NULL);
        pthread_join(tid2[i],NULL);
    }
    pthread_mutex_destroy(&p_lock);
    pthread_cond_destroy(&p_cond);
    
}
void *decrement_count(void *arg)
{
    
    pthread_mutex_lock(&p_lock);
    NSLog(@" ---- 线程1");
    while(!count)
    {
        pthread_cond_wait(&p_cond, &p_lock);
    }
    NSLog(@"-----线程1 index -- : %d",count);
    
    sleep(1);
    count --;
    NSLog(@"-----线程1 index -- over : %d",count+1);
    
    pthread_mutex_unlock(&p_lock);
    return 0;
}

void *increment_count(void *arg)
{
    pthread_mutex_lock(&p_lock);
    NSLog(@" **** 线程2");
    NSLog(@"***** 线程2 index --: %d",count+1);
    sleep(1);
    count++;
    NSLog(@"-----线程2 index -- over : %d",count);
    
    pthread_cond_signal(&p_cond);
    pthread_mutex_unlock(&p_lock);
    return 0;
}





//信号量
- (IBAction)dispatch_semaphore:(id)sender {
    NSLog(@"\n\n***********************");

    dispatch_semaphore_t signal = dispatch_semaphore_create(2);
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程1");
        sleep(2);
        NSLog(@"线程 1 over");
        dispatch_semaphore_signal(signal);
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程2");
        sleep(2);
        NSLog(@"线程 2 over");
        dispatch_semaphore_signal(signal);
    });
    

}



- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
