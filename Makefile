#
#   Athix Kernel's root Makefile
#

KCONFIG_CONFIG := .config
KCONFIG_EXE := kconfig-mconf

include config/meta
include config/toolchain
include config/building

.PHONY: all menuconfig build clean help

# Define source directories
SRC_DIRS := sys

# Get a list of all C and C++ source files in the specified directories
CCFILES := $(shell find $(SRC_DIRS) -name '*.c' -or -name '*.cpp')

# Create object files list from source files
OBJS := $(CCFILES:.c=.o)
OBJS := $(OBJS:.cpp=.o)

# Targets
all: build

menuconfig: $(KCONFIG_CONFIG)

$(KCONFIG_CONFIG): Kconfig
	@$(KCONFIG_EXE) Kconfig

ifeq ("$(wildcard $(KCONFIG_CONFIG))", "")
else
    include $(KCONFIG_CONFIG)
endif

ifeq ("$(wildcard $(KCONFIG_CONFIG))", "")
BUILD_TYPE := Unknown
DEBUG := 0
VERBOSE := 0
else
    ifeq ($(CONFIG_BUILD_TYPE_DEBUG),y)
        BUILD_TYPE := Debug
		DEBUG := 1
    else ifeq ($(CONFIG_BUILD_TYPE_RELEASE),y)
        BUILD_TYPE := Release
		DEBUG := 0
    else
        BUILD_TYPE := Unknown
		DEBUG := 0
    endif

    ifeq ($(CONFIG_KERNEL_VERBOSE),y)
        VERBOSE := 1
    else
        VERBOSE := 0
    endif
endif

deps:
	@set -e; ./tools/deps external deps.json

limine:
	@set -e; ./tools/limine limine

athix-kernel: $(OBJS)
	@printf "  LD\t$@\n"
	@$(LD) $(LDFLAGS) $(OBJS) -o athix-kernel

%.o: %.c
	@printf "  CC\t$<\n"
	@$(CC) $(CCFLAGS) $(CXXFLAGS) -D_ATHIX_VERBOSE=$(VERBOSE) -D_ATHIX_DEBUG=$(DEBUG) -c $< -o $@

%.o: %.cpp
	@printf "  CXX\t$<\n"
	@$(CXX) $(CCFLAGS) $(CXXFLAGS) -D_ATHIX_VERBOSE=$(VERBOSE) -D_ATHIX_DEBUG=$(DEBUG) -c $< -o $@

build: deps limine athix-kernel

clean:
	rm -f $(KCONFIG_CONFIG)
	rm -f $(OBJS)
	rm -f athix-kernel
	rm -rf external
	rm -rf limine

help:
	@echo "Athix Kernel Makefile Commands:"
	@echo "  make menuconfig    - Configure the build options."
	@echo "  make               - Build the Athix kernel."
	@echo "  make clean         - Clean the build files."
	@echo "  make help          - Show this help message."
