TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += SandyXpcTestTweak

SandyXpcTestTweak_ARCHS := arm64 arm64e
SandyXpcTestTweak_FILES += SandyXpcTestTweak.mm
SandyXpcTestTweak_CFLAGS += -fobjc-arc
SandyXpcTestTweak_LIBRARIES += SandyXpc

include $(THEOS_MAKE_PATH)/tweak.mk

TOOL_NAME = SandyXpcTestDaemon

SandyXpcTestDaemon_ARCHS := arm64
SandyXpcTestDaemon_FILES += SandyXpcTestDaemon.mm
SandyXpcTestDaemon_CFLAGS += -fobjc-arc
SandyXpcTestDaemon_LIBRARIES += SandyXpc
SandyXpcTestDaemon_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
