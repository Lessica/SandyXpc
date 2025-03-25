ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME += libSandyXpc

libSandyXpc_USE_MODULES := 0
libSandyXpc_INSTALL := 1
libSandyXpc_INSTALL_TO_THEOS := 1

libSandyXpc_FILES += SandyXpcConnection.m
libSandyXpc_FILES += SandyXpcMessagingCenter.m
libSandyXpc_FILES += MachXPC/MachXPCConnection.m
libSandyXpc_FILES += MachXPC/MachXPCHost.m
libSandyXpc_FILES += MachXPC/MachXPCListener.m
libSandyXpc_FILES += MachXPC/MachXPCService.m
libSandyXpc_FILES += MachXPC/SXXFindSymbols.m

libSandyXpc_CFLAGS += -fobjc-arc
libSandyXpc_CFLAGS += -I. -Iheaders

libSandyXpc_LDFLAGS += -install_name @rpath/libSandyXpc.dylib
libSandyXpc_FRAMEWORKS += CoreFoundation Foundation

libSandyXpc_INSTALL_PATH := /usr/lib
libSandyXpc_PUBLIC_HEADERS += libSandyXpc.h

include $(THEOS_MAKE_PATH)/library.mk

after-stage::
	@cp -v "./libSandyXpc.h" "$(THEOS)/include"
