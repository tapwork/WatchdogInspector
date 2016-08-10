//
//  TWWatchdogInspector.h
//  Tapwork GmbH
//
//  Created by Christian Menschel on 25/01/16.
//
//

#import <Foundation/Foundation.h>

@interface TWWatchdogInspector : NSObject

/**
 *  Starts the WatchdogInspector
 */
+ (void)start;

/**
 *  Stops the WatchdogInspector
 */
+ (void)stop;

/**
 * Check for activity
 * @return YES If WatchdogInspector is running
 *
 */
+ (BOOL)isRunning;

/**
 *  If the mainthread stalls longer than this given time,
 *  an exception will be thrown.
 *  Default is 3 seconds
 *  @param time The timeout in seconds for mainthread stalling.
 */
+ (void)setStallingThreshhold:(NSTimeInterval)time;

/**
 *  Tell WatchdogInspector if you want to disable or enable
 *  the stalling exceptions.
 *  Default is YES (turned on)
 *  @param enable If you want to enable or disable the stalling exceptions.
 */
+ (void)setEnableMainthreadStallingException:(BOOL)enable;

/**
 *  Set the update time interval for the background thread timer.
 *  The background thread timer counts the frames that have been set 
 *  by the main thread in that time interval
 *  The update interval should not below 0.5 seconds for performance reasons.
 *  Default is 2 seconds
 *  @param time The interval to measure the frames
 */
+ (void)setUpdateWatchdogInterval:(NSTimeInterval)time;

/**
 *  Turn off or on the NSLogs for framerate in fps
 *
 *  Default is on;
 *  @param useLogs - Turn on to use NSLogs
 */
+ (void)setUseLogs:(BOOL)useLogs;

@end
