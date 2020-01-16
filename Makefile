ARCHS = arm64

INSTALL_TARGET_PROCESSES = nfcd

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NFCBackgroundEnabler

NFCBackgroundEnabler_FILES = Tweak.xm
NFCBackgroundEnabler_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
