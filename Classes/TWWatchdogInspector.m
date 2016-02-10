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

static TWWatchdogInspectorStatusBarView *statusBarView = nil;
static int numberOfFrames = 0;
static BOOL useLogs = YES;
static CFTimeInterval lastFramePingTime = 0;
static dispatch_source_t watchdogTimer;
static CFRunLoopTimerRef mainthreadTimer;
static NSString *const kExceptionName = @"TWWatchdogInspectorStallingTimeout";

@implementation TWWatchdogInspector

static void mainthreadTimerCallback(CFRunLoopTimerRef timer, void *info)
{
    numberOfFrames++;
    updateLastPingTime();
}

static void updateLastPingTime()
{
    lastFramePingTime = CACurrentMediaTime();
}

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
    
    updateLastPingTime();
    
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
            
            CFTimeInterval stallingTime = CACurrentMediaTime() - lastFramePingTime;
            if (stallingTime > watchdogMaximumStallingTimeInterval) {
                [self throwExceptionForStallingTimeout:stallingTime];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                statusBarView.fps = fps;
            });
        });
        dispatch_resume(watchdogTimer);
    }
}

+ (void)throwExceptionForStallingTimeout:(NSTimeInterval)stallingTime
{
    NSString *reason = [NSString stringWithFormat:@"Watchdog timeout: Mainthread stalled for %.2f seconds", stallingTime];
    NSException *excetopion = [NSException exceptionWithName:kExceptionName
                                                      reason:reason
                                                    userInfo:nil];
    [excetopion raise];
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
