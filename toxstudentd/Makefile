include $(THEOS)/makefiles/common.mk

TWEAK_NAME = toxstudentd
toxstudentd_FILES = Tweak.xm
toxstudentd_PRIVATEFRAMEWORKS = SpringBoardServices ManagedConfiguration
toxstudentd_ARCHS = arm64

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 studentd"
