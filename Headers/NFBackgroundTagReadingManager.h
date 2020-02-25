#import "NBETagLockProvider/NBETagLockProvider.h"

@interface NFBackgroundTagReadingManager {
	NFDriverWrapper *_driverWrapper;
	bool _airplaneMode;
}
@property(nonatomic, retain) NBETagLockProvider *tagLockProvider;
- (id)initWithQueue:(id)arg1 driverWrapper:(id)arg2 lpcdHWSupport:(bool)arg3;
- (void)didScreenStateChange:(bool)arg1;
- (bool)updateAirplaneMode;
@end