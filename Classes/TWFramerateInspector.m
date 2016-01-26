//
//  TWFramerateInspector.m
//  Tapwork GmbH
//
//  Created by Christian Menschel on 25/01/16.
//
//

#import "TWFramerateInspector.h"
#include <mach/mach_time.h>
#import <execinfo.h>

static CFRunLoopObserverRef kObserverRef;
static CFTimeInterval kLoopTimeEntry = 0.0;

@implementation TWFramerateInspector

static void runloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    CFRunLoopActivity currentActivity = activity;
    switch (currentActivity) {
        case kCFRunLoopAfterWaiting:
            kLoopTimeEntry = CACurrentMediaTime();
            break;

        case kCFRunLoopBeforeWaiting:
        {
            CFTimeInterval time = CACurrentMediaTime() - kLoopTimeEntry;
            
            if (1/time <= 60 && 1/time >= 1) {
                NSLog(@"fps %@", @(1/time));
            }
        }
            break;

        default:
            break;
    }
}

+ (void)start
{
    [self stop];
    CFRunLoopObserverContext context = {0, (__bridge void *)(self),
        NULL,
        NULL,
        NULL
    };
    
    kObserverRef = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserverCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
}

+ (void)stop
{
    if (kObserverRef) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
        CFRelease(kObserverRef);
        kObserverRef = nil;
    }
}

- (void)dealloc
{
    [[self class] stop];
}

@end
