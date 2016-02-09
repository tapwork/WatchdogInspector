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

static CFTimeInterval watchdogMaximumStallingTimeInterval = 3.0;
static const CFTimeInterval kUpdateWatchdogInterval = 2.0;
static const double kBestWatchdogFramerate = 60.0;

static UILabel *textLabel = nil;
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

    if (!textLabel) {
        [self setupStatusBarLabel];
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
                [self updateColorWithFPS:fps];
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

+ (void)updateColorWithFPS:(double)fps
{
    //fade from green to red
    double n = 1 - (fps/60);
    double red = (255 * n);
    double green = (255 * (1 - n)/2);
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (fps > 0.0) {
        textLabel.backgroundColor = color;
        textLabel.text = [NSString stringWithFormat:@"fps: %.2f", fps];
    } else {
        textLabel.backgroundColor = [UIColor lightGrayColor];
        textLabel.text = nil;
    }
}

+ (void)setupStatusBarLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor lightGrayColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [UIFont systemFontOfSize:11];
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    label.frame = CGRectMake(0, 0, size.width, size.height);
    [TWYourStatusBar setCustomView:label];
    textLabel = label;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [[self class] stop];
}

@end
