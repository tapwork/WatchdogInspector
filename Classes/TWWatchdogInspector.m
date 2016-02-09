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

static CFRunLoopObserverRef kObserverRef;
static double kBestWatchdog = 60.0;
static UILabel *kTextLabel = nil;
static int kNumberOfFrames = 0;
static CFTimeInterval kUpdateWatchdogInterval = 2.0;
static CFTimeInterval kWatchdogTreshholdTimeInterval = 0.2;
static dispatch_source_t kWatchdogTimer;

@implementation TWWatchdogInspector

static void timerWatchdogCallback(CFRunLoopTimerRef timer, void *info)
{
    kNumberOfFrames++;
}

static void runloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    if (activity == kCFRunLoopAfterWaiting) {
        NSLog(@"====================");
        NSLog(@"entry");
    } else if (activity == kCFRunLoopBeforeWaiting) {
        NSLog(@"exit");
        NSLog(@"====================");
    }
}

static void updateColorWithWatchdog(double Watchdog)
{
    //fade from green to red
    double n = 1 - (Watchdog/60);
    double red = (255 * n);
    double green = (255 * (1 - n)/2);
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (Watchdog > 0.0) {
        kTextLabel.backgroundColor = color;
        kTextLabel.text = [NSString stringWithFormat:@"fps: %.2f", Watchdog];
    } else {
        kTextLabel.backgroundColor = [UIColor lightGrayColor];
        kTextLabel.text = nil;
    }
}

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
 
    [self addWatchdogTimer];
    [self addMainThreadWatchdogCounter];
 //   [self addRunLoopObserver];

    if (!kTextLabel) {
        [self setupStatusBarLabel];
    }
}

+ (void)addMainThreadWatchdogCounter
{
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFRunLoopTimerContext timerContext = {0, NULL, NULL, NULL, NULL};
    CFTimeInterval updateWatchdog = 1/kBestWatchdog;
    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                                   0,
                                                   updateWatchdog,
                                                   0,
                                                   0,
                                                   &timerWatchdogCallback,
                                                   &timerContext);

    CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes);
}

+ (void)addRunLoopObserver
{
    CFRunLoopObserverContext context = {0, (__bridge void *)(self),
        NULL,
        NULL,
        NULL
    };
    
    kObserverRef = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                           kCFRunLoopAllActivities,
                                           YES,
                                           0,
                                           &runloopObserverCallback,
                                           &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
}

+ (void)addWatchdogTimer
{
    kWatchdogTimer = createDispatchTimer(kUpdateWatchdogInterval * NSEC_PER_SEC,
                                         (kUpdateWatchdogInterval * NSEC_PER_SEC) / 10,
                                         dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                             
                                             double fps = kNumberOfFrames/kUpdateWatchdogInterval;
                                             kNumberOfFrames = 0;
                                             NSLog(@"fps %.2f", fps);
                                             CFTimeInterval startTime = CACurrentMediaTime();
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 updateColorWithWatchdog(fps);
                                                 CFTimeInterval endTime = CACurrentMediaTime();
                                                 if (endTime - startTime > kWatchdogTreshholdTimeInterval) {
                                                     NSLog(@"Mainthread stalled for %.2f seconds", endTime - startTime);
                                                 }
                                             });
                                         });
}

dispatch_source_t createDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

+ (void)stop
{
    if (kObserverRef) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), kObserverRef, kCFRunLoopCommonModes);
        CFRelease(kObserverRef);
        kObserverRef = nil;
    }
    
    if (kWatchdogTimer && dispatch_source_get_handle(kWatchdogTimer)) {
        dispatch_source_cancel(kWatchdogTimer);
    }

    kWatchdogTimer = nil;
}

- (void)dealloc
{
    [[self class] stop];
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

@end
