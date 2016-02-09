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
 *  The timeout in seconds for mainthread stalling.
 *  If the mainthread stalls longer than this given time,
 *  an exception will be thrown.
 *  Default is 3 seconds
 */
+ (void)setStallingThreshhold:(NSTimeInterval)time;

/**
 *  Turn off or on the NSLogs for framerate in fps
 *
 *  Default is on;
 */
+ (void)setUseLogs:(BOOL)useLogs;

@end
