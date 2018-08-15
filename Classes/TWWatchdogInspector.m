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
#import "TWWatchdogInspectorViewController.h"

static const double kBestWatchdogFramerate = 60.0;
static NSString *const kExceptionName = @"TWWatchdogInspectorStallingTimeout";

static UIWindow *kInspectorWindow = nil;

static CFTimeInterval updateWatchdogInterval = 2.0;
static CFTimeInterval watchdogMaximumStallingTimeInterval = 3.0;
static BOOL enableWatchdogStallingException = YES;
static int numberOfFrames = 0;
static BOOL useLogs = YES;
static CFTimeInterval lastMainThreadEntryTime = 0;
static dispatch_source_t watchdogTimer = NULL;
static CFRunLoopTimerRef mainthreadTimer = NULL;
static CFRunLoopObserverRef kObserverRef = NULL;

static void mainthreadTimerCallback(CFRunLoopTimerRef timer, void *info)
{
    numberOfFrames++;
}

@implementation TWWatchdogInspector

#pragma mark - Public methods

+ (void)start
{
    if (useLogs) {
        NSLog(@"Start WatchdogInspector");
    }
    [self addRunLoopObserver];
    [self addWatchdogTimer];
    [self addMainThreadWatchdogCounter];
    if (!kInspectorWindow) {
        [self setupStatusView];
    }
}

+ (void)stop
{
    if (useLogs) {
        NSLog(@"Stop WatchdogInspector");
    }
    if (watchdogTimer) {
        dispatch_source_cancel(watchdogTimer);
        watchdogTimer = NULL;
    }

    if (mainthreadTimer) {
        CFRunLoopTimerInvalidate(mainthreadTimer);
        mainthreadTimer = NULL;
    }
    
    if (kObserverRef) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
        CFRelease(kObserverRef);
        kObserverRef = NULL;
    }
    [self resetCountValues];
    [kInspectorWindow setHidden:YES];
    kInspectorWindow = nil;
}

+ (BOOL)isRunning
{
    return (watchdogTimer != NULL);
}

+ (void)setStallingThreshhold:(NSTimeInterval)time
{
    watchdogMaximumStallingTimeInterval = time;
}

+ (void)setEnableMainthreadStallingException:(BOOL)enable
{
    enableWatchdogStallingException = enable;
}

+ (void)setUpdateWatchdogInterval:(NSTimeInterval)time
{
    updateWatchdogInterval = time;
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
        dispatch_source_set_timer(watchdogTimer, dispatch_walltime(NULL, 0), updateWatchdogInterval * NSEC_PER_SEC, (updateWatchdogInterval * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(watchdogTimer, ^{
            double fps = numberOfFrames/updateWatchdogInterval;
            numberOfFrames = 0;
            if (useLogs) {
                NSLog(@"fps %.2f", fps);
            }
            [self throwExceptionForStallingIfNeeded];
            dispatch_async(dispatch_get_main_queue(), ^{
                [((TWWatchdogInspectorViewController *)kInspectorWindow.rootViewController) updateFPS:fps];
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
    if (enableWatchdogStallingException) {
        CFTimeInterval time = CACurrentMediaTime() - lastMainThreadEntryTime;
        if (time > watchdogMaximumStallingTimeInterval && lastMainThreadEntryTime > 0) {
            NSString *reason = [NSString stringWithFormat:@"Watchdog timeout: Mainthread stalled for %.2f seconds", time];
            NSException *excetopion = [NSException exceptionWithName:kExceptionName
                                                              reason:reason
                                                            userInfo:nil];
            [excetopion raise];
        }
    }
}

+ (void)resetCountValues {
    lastMainThreadEntryTime = 0;
    numberOfFrames = 0;
}

#pragma mark - UI Updates

+ (void)setupStatusView
{
#if TARGET_OS_IOS
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
#elif TARGET_OS_TV
    CGRect statusBarFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 54);
#endif
    CGSize size =  statusBarFrame.size;
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    UIWindow *window = [[UIWindow alloc] initWithFrame:frame];
    window.rootViewController = [[TWWatchdogInspectorViewController alloc] init];
    [window setHidden:NO];
#if TARGET_OS_IOS
    window.windowLevel = UIWindowLevelStatusBar + 50;
#elif TARGET_OS_TV
    window.windowLevel = UIWindowLevelNormal + 50;
#endif
    kInspectorWindow = window;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [[self class] stop];
}

@end
