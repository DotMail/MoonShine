//
//  MSHUpdater.m
//  MoonShine
//
//  Created by Robert Widmann on 5/16/13.
//  Copyright (c) 2013 CodaFi. All rights reserved.
//

#import "MSHUpdater.h"
#import "AFNetworking.h"
#import "SUUnarchiver.h"
#import "SUHost.h"
#import "SUStandardVersionComparator.h"
#import "SUInstaller.h"

NSString *const MSHUpdaterUpdateAvailableNotification = @"DMUpdaterUpdateAvailableNotification";

typedef NS_ENUM(NSUInteger, DMUpdaterState) {
	DMUpdaterStateIdle,
	DMUpdaterStateChecking,
	DMUpdaterStateFetchingUpdate,
	DMUpdaterStateRecievedUpdate,
	DMUpdaterStateInstallingUpdate,
};

@interface MSHUpdater ()

@property (nonatomic, assign) DMUpdaterState state;
@property (nonatomic, strong) NSOperationQueue *updateQueue;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSURL *downloadFolder;

@end

@implementation MSHUpdater

+ (instancetype)standardUpdater {
	static MSHUpdater *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	self = [super init];
	
	_updateQueue = [[NSOperationQueue alloc]init];
	[_updateQueue setMaxConcurrentOperationCount:1];
	[_updateQueue setName:@"com.CodaFi.MoonShine.UpdateQueue"];
	
	return self;
}

- (void)setUpdateTimer:(NSTimer *)updateTimer {
	if (updateTimer != _updateTimer) {
		[_updateTimer invalidate];
		_updateTimer = nil;
		_updateTimer = updateTimer;
		[self checkForUpdates];
	}
}

- (void)beginAutomaticUpdateChecksAtInterval:(NSTimeInterval)interval {
	@weakify(self);
	dispatch_async(dispatch_get_main_queue(), ^{
		@strongify(self);
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdates) userInfo:nil repeats:YES];
		[self setUpdateTimer:timer];
	});
}

- (void)checkForUpdates {
	if (self.state == DMUpdaterStateIdle) {
		self.state = DMUpdaterStateChecking;
		AFHTTPRequestOperationManager *manager = AFHTTPRequestOperationManager.manager;
		AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializerWithReadingOptions:0];
		serializer.acceptableContentTypes = [serializer.acceptableContentTypes setByAddingObject:@"text/plain"];
		manager.responseSerializer = serializer;
		[manager GET:@"https://raw.github.com/DotMail/Luna/master/latest.json" parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
			if ([JSON isKindOfClass:NSDictionary.class]) {
				NSString *installURLString = JSON[@"URL"];
				NSComparisonResult compareResult = [SUStandardVersionComparator.defaultComparator compareVersion:NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] toVersion:JSON[@"Version"]];
				NSString *releaseNotes = JSON[@"Notes"];
				if (compareResult == NSOrderedAscending) {
					if (installURLString) {
						NSError *error = nil;
						NSString *tempInstallPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.CodaFi.MoonShine"];
						NSURL *tempInstallLocation = [NSURL fileURLWithPath:tempInstallPath];
						BOOL tempFileCreated = [NSFileManager.defaultManager createDirectoryAtURL:tempInstallLocation withIntermediateDirectories:YES attributes:nil error:&error];
						if (tempFileCreated) {
							NSString *updateTempPath = [tempInstallPath stringByAppendingPathComponent:@"update.XXXXXX"];
							const char *updateTempPathFileSystemRep = updateTempPath.fileSystemRepresentation;
							void *updateTempPathCpy = calloc(strlen(updateTempPathFileSystemRep) + 1, 1);
							strncpy(updateTempPathCpy, updateTempPathFileSystemRep, strlen(updateTempPathFileSystemRep));
							if (mkdtemp(updateTempPathCpy) != NULL) {
								free(updateTempPathCpy);
								self.downloadFolder = [NSURL fileURLWithPath:tempInstallPath];
								NSURL *downloadFileURL = [self.downloadFolder URLByAppendingPathComponent:installURLString.lastPathComponent];
								NSOutputStream *stream = [[NSOutputStream alloc]initWithURL:downloadFileURL append:NO];
								AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc]initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:installURLString]]];
								@weakify(self);
								[request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
									@strongify(self);
									self.state = DMUpdaterStateRecievedUpdate;
									SUHost *host = [[SUHost alloc] initWithBundle:NSBundle.mainBundle];
									SUUnarchiver *unarchiver = [SUUnarchiver unarchiverForPath:downloadFileURL.path updatingHost:host];
									[unarchiver setCompletion:^(BOOL success) {
										if (success) {
											NSString *bundlePath = [downloadFileURL.path.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"DotMail.app"];
											if ([NSBundle bundleWithPath:bundlePath] != nil) {
												[self verifyCodeSignatureOfBundle:[NSBundle bundleWithPath:bundlePath] completion:^(BOOL success) {
													if (!success) {
														[self bailOut];
														return;
													}
													dispatch_async(dispatch_get_main_queue(), ^{
														self.releaseNotes = releaseNotes;
														[NSNotificationCenter.defaultCenter postNotificationName:MSHUpdaterUpdateAvailableNotification object:releaseNotes userInfo:nil];
													});
												}];
											} else {
												[self bailOut];
											}
										} else {
											[self bailOut];
										}
									} callbackQueue:NULL];
									[unarchiver start];
								} failure:^(AFHTTPRequestOperation *operation, NSError *error) { [self bailOut]; }];
								[request setOutputStream:stream];
								self.state = DMUpdaterStateFetchingUpdate;
								[_updateQueue addOperation:request];
							} else {
								[self bailOut];
							}
						} else {
							[self bailOut];
						}
					} else {
						[self bailOut];
					}
				} else {
					[self bailOut];
				}
			} else {
				[self bailOut];
			}
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) { [self bailOut]; }];
	}
}

// Ripped from Sparkle.  See:
// https://github.com/andymatuschak/Sparkle/blob/0ed83cf9f2eeb425d4fdd141c01a29d843970c20/SUCodeSigningVerifier.m
- (void)verifyCodeSignatureOfBundle:(NSBundle *)newBundle completion:(void(^)(BOOL))completion {
	if (SecCodeCopySelf == NULL) return completion(NO);
	
	OSStatus result = 0;
	SecRequirementRef requirement = NULL;
	SecStaticCodeRef staticCode = NULL;
	SecCodeRef hostCode = NULL;
	
	result = SecCodeCopySelf(kSecCSDefaultFlags, &hostCode);
	if (result != 0) {
		NSLog(@"Failed to copy host code %d", result);
		goto finally;
	}
	
	result = SecCodeCopyDesignatedRequirement(hostCode, kSecCSDefaultFlags, &requirement);
	if (result != 0) {
		NSLog(@"Failed to copy designated requirement %d", result);
		goto finally;
	}
	
	if (!newBundle) {
		NSLog(@"Failed to load NSBundle for update");
		result = -1;
		goto finally;
	}
	
	result = SecStaticCodeCreateWithPath((__bridge CFURLRef)[newBundle executableURL], kSecCSDefaultFlags, &staticCode);
	if (result != 0) {
		NSLog(@"Failed to get static code %d", result);
		goto finally;
	}
	
	CFErrorRef cfError;
	result = SecStaticCodeCheckValidityWithErrors(staticCode, kSecCSDefaultFlags | kSecCSCheckAllArchitectures, requirement, &cfError);

finally:
	if (hostCode) CFRelease(hostCode);
	if (staticCode) CFRelease(staticCode);
	if (requirement) CFRelease(requirement);
	return completion(result == 0);
}

- (BOOL)installUpdateIfNeeded {
	if (self.state == DMUpdaterStateRecievedUpdate) {
		if (self.downloadFolder != nil) {
			self.state = DMUpdaterStateInstallingUpdate;
			SUHost *host = [[SUHost alloc] initWithBundle:NSBundle.mainBundle];
			[SUInstaller installFromUpdateFolder:self.downloadFolder.path overHost:host delegate:nil synchronously:YES versionComparator:[SUStandardVersionComparator defaultComparator]];
			return YES;
		}
	}
	return NO;
}

- (void)bailOut {
	self.releaseNotes = nil;
	if (self.downloadFolder != nil) {
		NSError *error = nil;
		if (![NSFileManager.defaultManager removeItemAtURL:self.downloadFolder error:&error]) {
			NSLog(@"Failed to remove downloads folder at path %@", self.downloadFolder);
		}
		self.downloadFolder = nil;
	}
	self.state = DMUpdaterStateIdle;
}

@end
