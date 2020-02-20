float protectionTime = 2;
float debounceTime = 1;
bool tagLockEnable = YES;

@interface NFDriverWrapper
- (_Bool)resumeDiscovery;
- (_Bool)checkTagPresence:(id)arg1;
- (_Bool)disconnectTag:(id)arg1 tagRemovalDetect:(_Bool)arg2;
- (_Bool)connectTag:(id)arg1;
@end

@interface NFTimer
- (void)stopTimer;
- (void)startTimer:(double)arg1 leeway:(double)arg2;
- (id)initWithCallback:(id)arg1 queue:(id)arg2;
@end

@interface NFBackgroundTagReadingManager
@property(nonatomic, retain) NSDate *dateOfLastScan;
@property(nonatomic, assign) bool shouldUpdateOnWake;
@end

%hook NFHardwareControllerInfo
- (_Bool)hasLPCDSupport {
	// Enables background tag detection.
	return YES;
}
%end

%hook NFTimer
- (void)startTimer:(double)time leeway:(double)leeway {
	/**
	*	_readermodeBurnoutProtectionDebounceTimer
	*	The timer that dictates how long to wait before a new session can start.
	*	Originally set for 5 seconds.
	*/
	const double debounceTimerTime = 5;

	if (time == debounceTimerTime) {
		%orig(debounceTime, leeway);
		HBLogInfo(@"DebounceTimer fired with: %f and: %f", debounceTime, leeway);
	}
	else {
		%orig();
	}
}
%end

%hook NFBackgroundTagReadingManager
%property(nonatomic, retain) NSDate *dateOfLastScan;
- (void)didScreenStateChange:(_Bool)state {
	%orig;
}

- (void)handleDetectedTags:(id)tags {
	HBLogInfo(@"Detected tags, count: %lu", [tags count]);

	/**
	*	_readermodeBurnoutProtectionTimer
	*	The timer that dictates how long a session can last.
	*	Modified here because it also affects app sessions.
	*/
	NFDriverWrapper *driverWrapper = MSHookIvar<NFDriverWrapper *>(self, "_driverWrapper");

	// start test
	// dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if ([driverWrapper connectTag:tags[0]]) {
			HBLogDebug(@"Tag %@", [driverWrapper checkTagPresence:tags[0]] ? @"present" : @"not Present");
			HBLogDebug(@"tag removal: %d", [driverWrapper disconnectTag:tags[0] tagRemovalDetect:YES]);
			HBLogDebug(@"Tag %@", [driverWrapper checkTagPresence:tags[0]] ? @"present" : @"not Present");
		}
	// });
	// end test

	NFTimer *protectionTimer = MSHookIvar<NFTimer *>(driverWrapper, "_readermodeBurnoutProtectionTimer");
	[protectionTimer stopTimer];

	HBLogInfo(@"Restarting Timer to: %f", protectionTime);
	[protectionTimer startTimer:protectionTime leeway:0.1];

	// if (self.dateOfLastScan) {
	// 	double timeSinceLastScan = [self.dateOfLastScan timeIntervalSinceNow] * -1;
	// 	float threshold = protectionTime + debounceTime + 1;
	// 	if (timeSinceLastScan < threshold) {
	// 		HBLogDebug(@"Skipping scan");
	// 		self.dateOfLastScan = [NSDate date];
	// 		return;
	// 	}
	// 	// HBLogDebug(@"timeSinceLastScan: %f", timeSinceLastScan);
	// }
	// self.dateOfLastScan = [NSDate date];

	%orig;
}
%end

static void reloadPreferences() {
	NSString *preferencesFilePath = [NSString stringWithFormat:@"/User/Library/Preferences/com.haotestlabs.nfcbackgroundenablerpreferences.plist"];
	
	NSData *fileData = [NSData dataWithContentsOfFile:preferencesFilePath];
	if (fileData) {
		NSError *error = nil;
		NSDictionary *preferences = [NSPropertyListSerialization propertyListWithData:fileData options:NSPropertyListImmutable format:nil error:&error];
		
		if (error) {
			HBLogError(@"Unable to read preference file, Error: %@", error);
		}
		else {
			if (preferences[@"ProtectionTime"]) {
				protectionTime = [preferences[@"ProtectionTime"] floatValue];
			}
			if (preferences[@"DebounceTime"]) {
				debounceTime = [preferences[@"DebounceTime"] floatValue];
			}
		}
	}
}

%ctor {
	reloadPreferences();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)reloadPreferences,
		CFSTR("com.haotestlabs.nfcbackgroundenablerpreferences.reload"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
}