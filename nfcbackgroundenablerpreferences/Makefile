include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NFCBackgroundEnablerPreferences

NFCBackgroundEnablerPreferences_FILES = NBEPRootListController.m
NFCBackgroundEnablerPreferences_INSTALL_PATH = /Library/PreferenceBundles
NFCBackgroundEnablerPreferences_FRAMEWORKS = UIKit
NFCBackgroundEnablerPreferences_PRIVATE_FRAMEWORKS = Preferences
NFCBackgroundEnablerPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NFCBackgroundEnablerPreferences.plist$(ECHO_END)
