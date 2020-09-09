#import "NBETagLockProvider/NBETagLockProvider.h"
#import "NBETagLockProvider/NBETagRemovalProtocol.h"
#import "NFTagInternal.h"

@interface NFBackgroundTagReadingManager <NBETagRemovalProtocol> {
	NFDriverWrapper *_driverWrapper;
	bool _airplaneMode;
}
@property(nonatomic, retain) NBETagLockProvider *tagLockProvider;
- (id)initWithQueue:(id)arg1 driverWrapper:(id)arg2 lpcdHWSupport:(bool)arg3;
- (void)didScreenStateChange:(bool)arg1;
- (bool)updateAirplaneMode;
- (id)_readNDEFFromTag:(NFTagInternal *)tag;

#pragma mark NBETagRemovalProtocol
- (void)tagPresenceRemoved;
@end
