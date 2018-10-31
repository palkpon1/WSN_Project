COMPONENT=Collection2SerialAppC
TINYOSDIR?=/home/wsn/tinyos-main/tos
TINYOS_ROOT_DIR?=/home/wsn/tinyos-main
PFLAGS+=-DRF230_DEF_RFPOWER=0xF
CFLAGS += -I$(TINYOSDIR)/lib/printf \
		  -I$(TINYOSDIR)/lib/net \
		  -I$(TINYOSDIR)/lib/net/le \
		  -I$(TINYOSDIR)/lib/net/ctp

include $(TINYOSDIR)/../Makefile.include