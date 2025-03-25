TARGET := iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES += SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += SandyXpcTestServer

SandyXpcTestServer_ARCHS := arm64 arm64e
SandyXpcTestServer_FILES += SandyXpcTestServer.mm
SandyXpcTestServer_CFLAGS += -fobjc-arc
SandyXpcTestServer_LIBRARIES += SandyXpc

include $(THEOS_MAKE_PATH)/tweak.mk

TOOL_NAME = SandyXpcTestClient

SandyXpcTestClient_ARCHS := arm64
SandyXpcTestClient_FILES += SandyXpcTestClient.mm
SandyXpcTestClient_CFLAGS += -fobjc-arc
SandyXpcTestClient_LIBRARIES += SandyXpc
SandyXpcTestClient_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
