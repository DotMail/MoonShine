//
//  MSHUpdater.h
//  MoonShine
//
//  Created by Robert Widmann on 5/16/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Posted when the updater finds a valid update.
FOUNDATION_EXPORT NSString *const MSHUpdaterUpdateAvailableNotification;

/**
 * An automatic update fetcher that interfaces with Luna on Github to first
 * download and parse a manifest, then update to the latest version of the
 * application.
 */
@interface MSHUpdater : NSObject

/// Returns the default updater instance.
+ (instancetype)standardUpdater;

/**
 * Begins automatic update checks at the specified interval (in seconds).
 */
- (void)beginAutomaticUpdateChecksAtInterval:(NSTimeInterval)interval;

/**
 * Runs the installer if an update has been downloaded and is ready to replace
 * the current running process.
 *
 * It is recommended that this be called after recieving 
 * `MSHUpdaterUpdateAvailableNotification`.
 */
- (BOOL)installUpdateIfNeeded;

/// The release notes, if any, from the most recently downloaded update.
@property (nonatomic, copy) NSString *releaseNotes;

@end
