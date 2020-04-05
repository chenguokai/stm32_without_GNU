# This is the Makefile templete for my stm32 project
# Copyright 2019 - 2020 Xim
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###################

BUILD_DIR = ./build
PROJECT_NAME = stm32

all: \
$(BUILD_DIR)/$(PROJECT_NAME).elf \
$(BUILD_DIR)/$(PROJECT_NAME).hex \
$(BUILD_DIR)/$(PROJECT_NAME).bin \
$(BUILD_DIR)/$(PROJECT_NAME).s \


###################
## build essential flags


COMPILER_PATH = /Users/cgk/Documents/clang_playground/toolchain/bin
PREFIX = $(COMPILER_PATH)/

LDSCRIPT = linker.ld
FAMILY = STM32F10X_MD
DEFINES = -D$(FAMILY) -DF103 
CFLAGS  = --target=arm-none-eabi \
          -c -march=armv7-m -mcpu=cortex-m3 -mthumb \
          -fno-common -nostdlib -fno-builtin -mlittle-endian -ffreestanding \
          -Wall -O0 -g  -fno-pic $(C_INCLUDES) \
          $(DEFINES)
MCU_SPEC  = cortex-m3

ASFLAGS += -c
ASFLAGS += -mcpu=$(MCU_SPEC)
ASFLAGS += -mthumb $(C_INCLUDES)
ASFLAGS += -Wall
# (Set error messages to appear on a single line.)
ASFLAGS += -fmessage-length=0
LDFLAGS = -fuse-ld=$(PREFIX)ld.lld
LLDFLAGS = -T$(LDSCRIPT)

###################

GENERIC_C_SOURCES =  main.c


C_SOURCES = \
./src/system_stm32f10x.c \
./src/stm32f10x_usart.c \
./src/stm32f10x_gpio.c \
./src/core_cm3.c \
./src/stm32f10x_rcc.c \
./src/misc.c \
./start.c \
stm32f10x_it.c \
$(GENERIC_C_SOURCES)



GENERIC_INCLUDES = \
-I./ \
-I./inc

C_INCLUDES =  \
$(GENERIC_INCLUDES)

ASM_SOURCES = \
# ./src/boot.S \

AS_DEBUG = -Wa,-a,-ad

###################
CC   = $(PREFIX)clang
AS   = $(PREFIX)clang -x assembler-with-cpp
COPY = $(PREFIX)llvm-objcopy
AR   = $(PREFIX)llvm-ar
SIZE = $(PREFIX)llvm-size
DUMP = $(PREFIX)llvm-objdump
GDB  = $(PREFIX)lldb
LD   = $(PREFIX)ld.lld

OPT = -Og

OBJECTS_ASM = $(ASM_SOURCES:.S=.o)
OBJECTS = $(C_SOURCES:.c=.o)


###################
## the objects to generate
$(OBJECTS_ASM): %.o: %.S
	@$(AS) $(ASFLAGS) $< -o $(BUILD_DIR)/$(notdir $@)
#@$(AS) $(ASFLAGS) -c $< -o $(BUILD_DIR)/$(notdir $@)

# You may add AS_DEBUG flag to see detailed output
# Omitted here for best experience
$(OBJECTS): %.o: %.c
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$(notdir $@)

$(BUILD_DIR)/$(PROJECT_NAME).elf: $(OBJECTS) $(OBJECTS_ASM)
	@echo "Building ELF files"
	@$(LD) $(LLDFLAGS) --lto-O3 $(addprefix $(BUILD_DIR)/, $(notdir $(OBJECTS_ASM))) $(addprefix $(BUILD_DIR)/, $(notdir @$(OBJECTS))) -o $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(COPY) -O ihex $< $@
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(COPY) -O binary -S $< $@
$(BUILD_DIR)/%.s: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(DUMP) -d $< > $@

###############--arch-name=thumb ####

clean:
	-rm -fR $(BUILD_DIR)/*
	find . -type f -name "*.d" -delete

debug:
	$(GDB) $(BUILD_DIR)/$(PROJECT_NAME).elf