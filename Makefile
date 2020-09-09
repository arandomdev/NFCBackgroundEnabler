export DEBUG = 0
export FINALPACKAGE = 1

export TARGET = iphone:clang:11.2:latest
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = nfcd

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NFCBackgroundEnabler

NFCBackgroundEnabler_FILES = Tweak.xm NBETagLockProvider/NBETagLockProvider.mm NSData+Conversion.m
NFCBackgroundEnabler_CFLAGS = -fobjc-arc
NFCBackgroundEnabler_FRAMEWORKS = CoreNFC

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += nfcbackgroundenablerpreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
