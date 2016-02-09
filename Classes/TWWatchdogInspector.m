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

static const CFTimeInterval kUpdateWatchdogInterval = 2.0;
static CFTimeInterval kWatchdogMaximumStallingTimeInterval = 3.0;
static const double kBestWatchdogFramerate = 60.0;

static UILabel *kTextLabel = nil;
static int kNumberOfFrames = 0;
static dispatch_source_t kWatchdogTimer;
static CFRunLoopTimerRef kMainthreadTimer;
static NSString *const kExceptionName = @"TWWatchdogInspectorStallingTimeout";

@implementation TWWatchdogInspector

static void mainthreadTimerCallback(CFRunLoopTimerRef timer, void *info)
{
    kNumberOfFrames++;
}

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
 
    [self addWatchdogTimer];
    [self addMainThreadWatchdogCounter];

    if (!kTextLabel) {
        [self setupStatusBarLabel];
    }
}

+ (void)stop
{
    if (kWatchdogTimer) {
        dispatch_source_cancel(kWatchdogTimer);
        kWatchdogTimer = nil;
    }

    if (kMainthreadTimer) {
        CFRunLoopTimerInvalidate(kMainthreadTimer);
        kMainthreadTimer = nil;
    }
}

+ (void)setStallingThreshhold:(NSTimeInterval)time
{
    kWatchdogMaximumStallingTimeInterval = time;
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
    kMainthreadTimer = timer;
}

+ (void)addWatchdogTimer
{
    kWatchdogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    if (kWatchdogTimer) {
        dispatch_source_set_timer(kWatchdogTimer, dispatch_walltime(NULL, 0), kUpdateWatchdogInterval * NSEC_PER_SEC, (kUpdateWatchdogInterval * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(kWatchdogTimer, ^{
            double fps = kNumberOfFrames/kUpdateWatchdogInterval;
            kNumberOfFrames = 0;
            NSLog(@"fps %.2f", fps);
            
            CFTimeInterval startTime = CACurrentMediaTime();
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateColorWithFPS:fps];
                CFTimeInterval endTime = CACurrentMediaTime();
                CFTimeInterval stallingTime = endTime - startTime;
                if (stallingTime > kWatchdogMaximumStallingTimeInterval) {
                    [self throwExceptionForStallingTimeout:stallingTime];
                }
            });
        });
        dispatch_resume(kWatchdogTimer);
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
        kTextLabel.backgroundColor = color;
        kTextLabel.text = [NSString stringWithFormat:@"fps: %.2f", fps];
    } else {
        kTextLabel.backgroundColor = [UIColor lightGrayColor];
        kTextLabel.text = nil;
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
    kTextLabel = label;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [[self class] stop];
}

@end
