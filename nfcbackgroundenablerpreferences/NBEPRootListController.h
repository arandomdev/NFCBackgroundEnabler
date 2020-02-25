#import <Preferences/PSListController.h>

@interface NBEPRootListController : PSListController
@property(nonatomic, assign) bool protectionTimeEnable;
- (NSArray *)specifiers;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier;
- (void)updateProtectionTimeEnable;
- (void)viewDidAppear:(BOOL)animated;
@end
