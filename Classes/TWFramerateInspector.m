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
#import <YourStatusBar/TWYourStatusBar.h>

static CFRunLoopObserverRef kObserverRef;
static double kBestFramerate = 60.0;
static UILabel *kTextLabel = nil;
static int kNumberOfFrames = 0;
static CFTimeInterval kUpdateWatchdogInterval = 2.0;
static dispatch_source_t kWatchdogTimer;
static dispatch_source_t kMainThreadTimer;

@implementation TWFramerateInspector

static void timerFramerateCallback(CFRunLoopTimerRef timer, void *info)
{
    kNumberOfFrames++;
}

static void updateColorWithFramerate(double framerate)
{
    //fade from green to red
    double n = 1 - (framerate/60);
    double red = (255 * n);
    double green = (255 * (1 - n)/2);
    double blue = 0;
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    if (framerate > 0.0) {
        kTextLabel.backgroundColor = color;
        kTextLabel.text = [NSString stringWithFormat:@"fps: %.2f", framerate];
    } else {
        kTextLabel.backgroundColor = [UIColor lightGrayColor];
        kTextLabel.text = nil;
    }
}

#pragma mark - Start / Stop

+ (void)start
{
    [self stop];
 
    [self addMainThreadFramerateCounter];
    [self addWatchdogTimer];

    if (!kTextLabel) {
        [self setupStatusBarLabel];
    }
}

+ (void)addMainThreadFramerateCounter
{
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFRunLoopTimerContext timerContext = {0, NULL, NULL, NULL, NULL};
    CFTimeInterval updateFramerate = 1/kBestFramerate;
    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                                   0,
                                                   updateFramerate,
                                                   0,
                                                   0,
                                                   &timerFramerateCallback,
                                                   &timerContext);

    CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes);
}

+ (void)addWatchdogTimer
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    kWatchdogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    dispatch_source_set_timer(kWatchdogTimer, dispatch_walltime(DISPATCH_TIME_NOW, NSEC_PER_SEC * kUpdateWatchdogInterval), kUpdateWatchdogInterval * NSEC_PER_SEC, 0);
    
    // Hey, let's actually do something when the timer fires!
    dispatch_source_set_event_handler(kWatchdogTimer, ^{
        double fps = kNumberOfFrames/kUpdateWatchdogInterval;
        NSLog(@"fps %.2f", fps);
        NSLog(@"====================");
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            kNumberOfFrames = 0;
            updateColorWithFramerate(fps);
        });
    });

    dispatch_resume(kWatchdogTimer);
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
    if (kMainThreadTimer && dispatch_source_get_handle(kMainThreadTimer)) {
        dispatch_source_cancel(kMainThreadTimer);
    }

    kWatchdogTimer = nil;
    kMainThreadTimer = nil;
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
