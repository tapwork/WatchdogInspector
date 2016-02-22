//
//  TWWatchdogInspector.m
//  Tapwork GmbH
//
//  Created by Christian Menschel on 25/01/16.
//
//

#import "TWWatchdogInspector.h"
#include <mach/mach_time.h>
#import <execinfo.h>
#import <YourStatusBar/TWYourStatusBar.h>
#import "TWWatchdogInspectorStatusBarView.h"

static CFTimeInterval watchdogMaximumStallingTimeInterval = 3.0;
static const CFTimeInterval kUpdateWatchdogInterval = 2.0;
static const double kBestWatchdogFramerate = 60.0;
static CFRunLoopObserverRef kObserverRef;
static TWWatchdogInspectorStatusBarView *statusBarView = nil;
static int numberOfFrames = 0;
static BOOL useLogs = YES;
static CFTimeInterval lastMainThreadEntryTime = 0;
static dispatch_source_t watchdogTimer;
static CFRunLoopTimerRef mainthreadTimer;
static NSString *const kExceptionName = @"TWWatchdogInspectorStallingTimeout";


static void mainthreadTimerCallback(CFRunLoopTimerRef timer, void *info)
{
    numberOfFrames++;
}

@implementation TWWatchdogInspector

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
    [self addRunLoopObserver];
    [self addWatchdogTimer];
    [self addMainThreadWatchdogCounter];

    if (!statusBarView) {
        [self setupStatusView];
    }
}

+ (void)stop
{
    if (watchdogTimer) {
        dispatch_source_cancel(watchdogTimer);
        watchdogTimer = nil;
    }

    if (mainthreadTimer) {
        CFRunLoopTimerInvalidate(mainthreadTimer);
        mainthreadTimer = nil;
    }
    
    if (kObserverRef) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
        CFRelease(kObserverRef);
        kObserverRef = nil;
    }
}

+ (void)setStallingThreshhold:(NSTimeInterval)time
{
    watchdogMaximumStallingTimeInterval = time;
}

+ (void)setUseLogs:(BOOL)use
{
    useLogs = use;
}

#pragma mark - Private methods

+ (void)addMainThreadWatchdogCounter
{
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFRunLoopTimerContext timerContext = {0, NULL, NULL, NULL, NULL};
    CFTimeInterval updateWatchdog = 1/kBestWatchdogFramerate;
    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                                   0,
                                                   updateWatchdog,
                                                   0,
                                                   0,
                                                   &mainthreadTimerCallback,
                                                   &timerContext);

    CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes);
    mainthreadTimer = timer;
}

+ (void)addWatchdogTimer
{
    watchdogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    if (watchdogTimer) {
        dispatch_source_set_timer(watchdogTimer, dispatch_walltime(NULL, 0), kUpdateWatchdogInterval * NSEC_PER_SEC, (kUpdateWatchdogInterval * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(watchdogTimer, ^{
            double fps = numberOfFrames/kUpdateWatchdogInterval;
            numberOfFrames = 0;
            if (useLogs) {
                NSLog(@"fps %.2f", fps);
            }
            [self throwExceptionForStallingIfNeeded];
            dispatch_async(dispatch_get_main_queue(), ^{
                [statusBarView updateFPS:fps];
            });
        });
        dispatch_resume(watchdogTimer);
    }
}

+ (void)addRunLoopObserver
{
    kObserverRef = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopAllActivities,
                                                      YES,
                                                      0,
                                                      ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity)
                                                      {
                                                          if (activity == kCFRunLoopAfterWaiting) {
                                                              lastMainThreadEntryTime = CACurrentMediaTime();
                                                          } else if (activity == kCFRunLoopBeforeTimers) {
                                                              [self throwExceptionForStallingIfNeeded];
                                                          }
                                                      });
    CFRunLoopAddObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
}

+ (void)throwExceptionForStallingIfNeeded
{
    CFTimeInterval time = CACurrentMediaTime() - lastMainThreadEntryTime;
    if (time > watchdogMaximumStallingTimeInterval && lastMainThreadEntryTime > 0) {
        NSString *reason = [NSString stringWithFormat:@"Watchdog timeout: Mainthread stalled for %.2f seconds", time];
        NSException *excetopion = [NSException exceptionWithName:kExceptionName
                                                          reason:reason
                                                        userInfo:nil];
        [excetopion raise];
    }
}

#pragma mark - UI Updates

+ (void)setupStatusView
{
    TWWatchdogInspectorStatusBarView *view = [[TWWatchdogInspectorStatusBarView alloc] init];
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    view.frame = CGRectMake(0, 0, size.width, size.height);
    [TWYourStatusBar setCustomView:view];
    statusBarView = view;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [[self class] stop];
}

@end
