float protectionTime = 2;
float debounceTime = 1;

@interface NFDriverWrapper
- (_Bool)resumeDiscovery;
- (_Bool)checkTagPresence:(id)arg1;
@end

@interface NFTimer
- (void)stopTimer;
- (void)startTimer:(double)arg1 leeway:(double)arg2;
- (id)initWithCallback:(id)arg1 queue:(id)arg2;
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
- (void)handleDetectedTags:(id)tags {
	HBLogInfo(@"Detected tags");
	%orig;

	/**
	*	_readermodeBurnoutProtectionTimer
	*	The timer that dictates how long a session can last.
	*	Modified here because it also affects app sessions.
	*/
	NFDriverWrapper *driverWrapper = MSHookIvar<NFDriverWrapper *>(self, "_driverWrapper");
	NFTimer *protectionTimer = MSHookIvar<NFTimer *>(driverWrapper, "_readermodeBurnoutProtectionTimer");
	[protectionTimer stopTimer];

	HBLogInfo(@"Restarting Timer to: %f: ", protectionTime);
	[protectionTimer startTimer:protectionTime leeway:0.1];
}
%end

static void reloadPreferences() {
	HBLogInfo(@"Reload preferences");
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
	HBLogInfo(@"Hooked");

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