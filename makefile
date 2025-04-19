# Makefile additions for DSP
CC_DSP = asm56000 -motorola -24bit
LDFLAGS += -ldsp_driver -lscsi_dma
CFLAGS += -DUSE_DSP=1 -DDSP_ARCH=56000