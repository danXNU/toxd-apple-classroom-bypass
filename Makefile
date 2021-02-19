include $(THEOS)/makefiles/common.mk

TOOL_NAME = toxd
toxd_FILES = main.mm
toxd_ARCHS = arm64
toxd_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/tool.mk
SUBPROJECTS += toxstudentd
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 toxd && killall -9 studentd"
