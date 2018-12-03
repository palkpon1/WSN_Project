COMPONENT=Collection2SerialAppC
TINYOSDIR?=/home/wsn/tinyos-main/tos
TINYOS_ROOT_DIR?=/home/wsn/tinyos-main
PFLAGS+=-DRF230_DEF_RFPOWER=0xF
SENSORBOARD=MTS310CA
CFLAGS += -I$(TINYOSDIR)/lib/printf \
		  -I$(TINYOSDIR)/lib/net \
		  -I$(TINYOSDIR)/lib/net/le \
		  -I$(TINYOSDIR)/lib/net/ctp \
		-I$(TINYOS_ROOT_DIR)/tos/sensorboards/mts300

include $(TINYOSDIR)/../Makefile.include