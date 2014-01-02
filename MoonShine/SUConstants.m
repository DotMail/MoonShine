//
//  SUConstants.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/16/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUConstants.h"

NSString *const SUUpdaterWillRestartNotification = @"SUUpdaterWillRestartNotificationName";
NSString *const SUTechnicalErrorInformationKey = @"SUTechnicalErrorInformation";

NSString *const SUHasLaunchedBeforeKey = @"SUHasLaunchedBefore";
NSString *const SUFeedURLKey = @"SUFeedURL";
NSString *const SUShowReleaseNotesKey = @"SUShowReleaseNotes";
NSString *const SUSkippedVersionKey = @"SUSkippedVersion";
NSString *const SUScheduledCheckIntervalKey = @"SUScheduledCheckInterval";
NSString *const SULastCheckTimeKey = @"SULastCheckTime";
NSString *const SUExpectsDSASignatureKey = @"SUExpectsDSASignature";
NSString *const SUPublicDSAKeyKey = @"SUPublicDSAKey";
NSString *const SUPublicDSAKeyFileKey = @"SUPublicDSAKeyFile";
NSString *const SUAutomaticallyUpdateKey = @"SUAutomaticallyUpdate";
NSString *const SUAllowsAutomaticUpdatesKey = @"SUAllowsAutomaticUpdates";
NSString *const SUEnableSystemProfilingKey = @"SUEnableSystemProfiling";
NSString *const SUEnableAutomaticChecksKey = @"SUEnableAutomaticChecks";
NSString *const SUEnableAutomaticChecksKeyOld = @"SUCheckAtStartup";
NSString *const SUSendProfileInfoKey = @"SUSendProfileInfo";
NSString *const SULastProfileSubmitDateKey = @"SULastProfileSubmissionDate";
NSString *const SUPromptUserOnFirstLaunchKey = @"SUPromptUserOnFirstLaunch";
NSString *const SUFixedHTMLDisplaySizeKey = @"SUFixedHTMLDisplaySize";
NSString *const SUKeepDownloadOnFailedInstallKey = @"SUKeepDownloadOnFailedInstall";
NSString *const SUDefaultsDomainKey = @"SUDefaultsDomain";

NSString *const SUSparkleErrorDomain = @"SUSparkleErrorDomain";
OSStatus SUAppcastParseError = 1000;
OSStatus SUNoUpdateError = 1001;
OSStatus SUAppcastError = 1002;
OSStatus SURunningFromDiskImageError = 1003;

OSStatus SUTemporaryDirectoryError = 2000;

OSStatus SUUnarchivingError = 3000;
OSStatus SUSignatureError = 3001;

OSStatus SUFileCopyFailure = 4000;
OSStatus SUAuthenticationFailure = 4001;
OSStatus SUMissingUpdateError = 4002;
OSStatus SUMissingInstallerToolError = 4003;
OSStatus SURelaunchError = 4004;
OSStatus SUInstallationError = 4005;
OSStatus SUDowngradeError = 4006;

OSErr SUGestalt(OSType selector, SInt32 *response) {
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7
	return Gestalt(selector, response);
#else
	NSArray *versionStrings = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"][@"ProductVersion"] componentsSeparatedByString:@"."];
	switch (selector) {
		case gestaltSystemVersionMajor:
			*response = [versionStrings[0] intValue];
			break;
		case gestaltSystemVersionMinor:
			*response = [versionStrings[1] intValue];
			break;
		case gestaltSystemVersionBugFix:
			*response = [versionStrings[2] intValue];
			break;
		default:
			break;
	}
	return -192; //File not found
#endif
}