COMPONENT=PARKINGAppC
TINYOS_ROOT_DIR?=/home/wsn/tinyos-main
TOSDIR?=/home/wsn/tinyos-main/tos
CFLAGS += "-DCC2420_DEF_RFPOWER=1"
CFLAGS += -I$(TOSDIR)/lib/printf
CFLAGS += -I$(TOSDIR)/lib/net \
          -I$(TOSDIR)/lib/net/le \
          -I$(TOSDIR)/lib/net/ctp
include $(TINYOS_ROOT_DIR)/Makefile.include