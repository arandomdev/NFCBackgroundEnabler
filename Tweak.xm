%hook NFHardwareControllerInfo
- (_Bool)hasLPCDSupport {
	return YES;
}
%end

@interface NFDriverWrapper
- (_Bool)resumeDiscovery;
@end

%hook NFBackgroundTagReadingManager
- (void)handleDetectedTags:(id)tags {
	HBLogDebug(@"Detected tags: %@", tags);
	%orig;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		NFDriverWrapper *driverWrapper = MSHookIvar<NFDriverWrapper *>(self, "_driverWrapper");
		[driverWrapper resumeDiscovery];
	});
}
%end

%ctor {
	HBLogDebug(@"Hooked");
}