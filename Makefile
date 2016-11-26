# Makefile for AutoQuad Flight Controller firmware
#
# ! Use of this makefile requires setup of a compatible development environment.
# ! For latest development recommendations, check the README file distributed with this project.
# ! This file is ignored when building with CrossWorks Studio.
#
# All paths are relative to Makefile location and most paths do not allow for spaces.
# Read the "Defaults" section below for all possible parameters (options) which are recognized.
#
# Possible make targets:
#  all         build firmware .elf, .hex, and .bin binaries
#  hex         build firmware .elf, and .hex binaries
#  bin         build firmware .elf, and .bin binaries
#  swd         build (if needed) and flash via SWD interface
#  dfu         build (if needed) and flash via USB (DFU) interface (board must be in bootloader mode)
#  sfl         build (if needed) and flash via Serial port interface (board must be in bootloader mode)
#  pack        create .zip archive of generated .hex and .bin files (requires GNU zip)
#  pack-hex    create .zip archive of generated .hex files
#  pack-bin    create .zip archive of generated .bin files
#  clean       delete all built objects (not binaries or archives)
#  clean-bin   delete all binaries created in build folder (*.elf, *.bin, *.hex)
#  clean-pack  delete all archives in build folder (*.zip)
#  clean-all   run all the above clean* steps.
#  size        run a memory report on an elf file (also automatically run after building elf file)
#
# Usage examples:
#   make all                                        # default Release type builds .elf, .hex, and .bin binaries
#   make all BUILD_TYPE=Debug                       # build with compiler debugging flags/options enabled
#   make all BOARD_REV=1 INCR_BUILDNUM=0            # build for rev 1 (post Oct-2012) hardware, don't increment the buildnumber
#   make hex BOARD_REV=1 DIMU_VER=1.1               # build only .hex file for rev 1 hardware with DIMU add-on board
#   make bin BOARD_VER=8 BOARD_REV=3 QUATOS=1       # build .bin file for AQ M4 hardware using Quatos (see note on QUATOS option, below)
#   make bin BOARD_VER=8 BOARD_REV=3 TOOLCHAIN=GAE  # build .bin file for AQ M4 hardware using GNU ARM Embedded toolchain
#
# 
# To get a proper size report after building, the GCC program "size" is needed (arm-none-eabi-size[.exe]). 
#  The SIZE variable (below) specifies its location. By default this is in the same folder as the compiler/build chain. However, 
#  the CrossWorks build chain does not provide one.  A copy can be obtained from many sources, 
#  eg. any recent version of https://launchpad.net/gcc-arm-embedded, Yagarto, etc.
#
# Windows needs some core GNU tools in your %PATH% (probably same place your "make" is). 
#    Required: gawk, mv, echo, rm, mkdir (see note)
#    Optional: expr (auto-incrmenent buildnumber), zip (to compress hex files using "make pack"), cat (to automatically read CW version file)
#   MKDIR Note: Check the EXE_MKDIR variable below -- due to a naming conflict with the Windows "mkdir", you may need to specify a full path for it.
#   Recommend GnuWin32 CoreUtils: http://gnuwin32.sourceforge.net/packages/coreutils.htm
#     or Cygwin which has an updated versin of "make" utility as well (just put the cygwin/bin folder in your PATH)
#

# Include user-specific settings file, if any, in regular Makefile format.
# This file can set any default variable values you wish to override (all defaults are listed below).
# The .user file is not included with the source code distribution, so it will not be overwritten.
-include Makefile.user

#
# Defaults - modify here, on command line, or in Makefile.user
#

# Target hardware-specific options
#

# Board version to build for (6=AQv6, 7=AQv7, 8=AQ M4, 10=AQ X)
BOARD_VER ?= 6

# Board revision to build for 
# For AQv6: 0=initial release, 1=Oct. 2012 revision)
# For AQ M4: 1-3=early prototypes, 4-5=beta boards, 6=Dec 2014 production (aka M4v2)
BOARD_REV ?= 1

# Specify a DIMU version number to enable DIMU support in AQv6, zero to disable (eg. DIMU_VER=1.1)
ifneq ($(findstring 6, $(BOARD_VER)),)
	DIMU_VER ?= 1.1
else
	DIMU_VER ?= 0
endif


# Build input and output options
#

# Output folder name; Use 'Debug' to set debug compiler options;
BUILD_TYPE ?= Release

# Where to put the built objects and binaries. Use any relative or absolute path (directory must alrady exist).
# A sub-folder is created along this path, named as the BUILD_TYPE (eg. build/Release).
BUILD_PATH ?= ../build

# Path to source files - no trailing slash
SRC_PATH ?= src

# Increment build number? (0|1)  This is automatically disabled for debug builds.
INCR_BUILDNUM ?= 0

# Produced binaries file name prefix (version/revision/build/hardware info will be automatically appended)
BIN_NAME ?= aq

# You may use BIN_SUFFIX to append text to generated bin file name after version string;
BIN_SUFFIX ?=

# Build debug version? (0|1; true by default if build_type contains the word "debug")
ifneq ($(findstring Debug, $(BUILD_TYPE)),)
	DEBUG_BUILD ?= 1
else 
	DEBUG_BUILD ?= 0
endif

# Build with Quatos controller enabled (0=no, 1=yes)
# NOTE: Must have pre-compiled quatos library file in lib/quatos (it is not distrubuted with this GPL source code)
#  Quatos is a proprietary attitude controller from drone-controls.com
QUATOS ?= 0

# Build with HILS enabled (0=no, 1=yes)
# NOTE: Must have pre-compiled hilSim library file in lib/hilsim
#  hilSim is a hardware-in-the-loop simulation support library from worlddesign.com
HIL_SIM ?= 0

# Whether to build all the CMSIS DSP library functions from source (1) or use pre-built lib (0)
BUILD_CMSIS_SRC ?= 0

# Whether to include float/double support for printf() (maybe useful for debug printing but increases FLASH & RAM usage)
PRINTF_FLOAT = 0

# Build with specific default parameters file (eg. CONFIG_FILE=config_default_m4.h)
CONFIG_FILE ?=

# Build with specific board (hardware) definitions file (eg. BOARD_FILE=board_custom.h)
BOARD_FILE ?=

# Add preprocessor definitions to CDEFS (eg. CC_ADD_VARS=-DCOMM_DISABLE_FLOW_CONTROL1 to disable flow control on USART 1)
CC_ADD_VARS ?=

# Additional C objects to compile
EXTRA_OBJECTS ?=


# Toolchain-specific options
#

# Toolchain: GAE (GNU ARM Embedded) or CW (Rowley Crossworks for ARM)
TOOLCHAIN ?= CW

# Crossworks version (required if using CW toolchain).
# If blank, this script will try to read version.txt file in the CW bin folder (requires UNIX "cat" utility).
# The major (first) number is most important. Others can be left off.
# eg: CW_VERSION ?= 3.7.1  or  CW_VERSION ?= 3.7
CW_VERSION ?=


# System-specific folder paths and commands
#

# Toolchain base path  (no spaces in paths!)
# eg for CW: CC_PATH ?= C:/devel/gcc/crossworks_for_arm_2.3
# eg for GNU ARM: CC_PATH ?= C:/devel/gcc/5.4
ifeq ($(TOOLCHAIN), CW)
	CC_PATH ?= /usr/share/crossworks_for_arm_2.3
else  # GNU ARM
	CC_PATH ?= /usr/share/gcc/5.4
endif

# shell commands
EXE_AWK ?= gawk 
EXE_MKDIR ?= mkdir
#EXE_MKDIR = C:/cygwin/bin/mkdir
EXE_TEST ?= test
EXE_CAT ?= cat
EXE_MV ?= mv
EXE_RM ?= rm
EXE_EXPR ?= expr
EXE_ZIP ?= zip -j
# file extention for compressed files (gz for gzip, etc)
ZIP_EXT ?= zip

# Flashing commands. Should be in PATH env. variable, or need to provide full directory path.
# Only necessary if flashing firmware with one of the swd/dfu/sfl make targets.
#
# Verify flash after programming (0 or 1)
FLASH_VRFY ?= 0
# SWD utilities: st-flash (https://github.com/texane/stlink) or ST-LINK_CLI for Windows (http://www.st.com/en/embedded-software/stsw-link004.html)
SWD_UTIL ?= $(if $(filter $(OS),Windows_NT),ST-LINK_CLI,st-flash)
# DFU utility: dfu-util (http://wiki.openmoko.org/wiki/Dfu-util)
DFU_UTIL ?= dfu-util
# Serial interface : https://sourceforge.net/p/stm32flash/wiki/Home/
SER_UTIL ?= stm32flash
# serial device for stm32flash.  eg. for Win: SER_DEV ?= COM3
SER_DEV  ?= /dev/ttyUSB0


# LIbrary paths
#

# Absolute or relative path to libraries/includes, no trailing slash.
# note: All required libraries are already included in project's source distribution.
AQLIB_PATH ?= lib

# Generated MAVLink header files (https://github.com/AutoQuad/mavlink_headers/tree/master/include)
MAVLINK_PATH ?= $(AQLIB_PATH)/mavlink/include/autoquad
# STM32F4 libs from ST (http://www.st.com/web/en/catalog/tools/PF257901)
STM32DRIVER_PATH ?= $(AQLIB_PATH)/STM32F4xx_StdPeriph_Driver
STM32CMSIS_PATH ?= $(AQLIB_PATH)/CMSIS
ARMDSPLIB_PATH ?= $(STM32CMSIS_PATH)/Lib
ARMDSPLIB_SRC ?= $(STM32CMSIS_PATH)/DSP_Lib/Source
# Proprietary Quatos attitude controller
QUATOS_PATH ?= $(AQLIB_PATH)/quatos
# Proprietary HILS library
HIL_SIM_PATH ?= $(AQLIB_PATH)/hilsim


# Low-level target hardware-specific options
#

# Processor type: STM32F407VG || STM32F427VG
ifeq ($(BOARD_VER), 10)
	ifeq ($(BOARD_REV), 1)
		MCU_VER ?= STM32F407VG
	else
		MCU_VER ?= STM32F427VG
	endif
else
	MCU_VER ?= STM32F407VG
endif

# Memory & placement linker scripts, should be in src/targets folder
LD_MEM_SCRIPT ?= memory_$(MCU_VER).ld
LD_PLC_SCRIPT ?= placement_heap_in_sram2_flash_ccm.ld

# Heap is used in firmware for temporary memory allocations. Stack is only used a little during low-level MCU setup.
# These get passed to the linker as symbols, then used in the placement script. Sizes in bytes.
HEAP_SIZE  ?= 16384 # size of SRAM2 segment
STACK_SIZE ?= 512


#
# Defaults end
#

#
## probably don't need to change anything below here ##
#

# build/object directory
OBJ_PATH = $(BUILD_PATH)/$(BUILD_TYPE)/obj
# bin file(s) output path
BIN_PATH = $(BUILD_PATH)/$(BUILD_TYPE)

# full linker script paths
LD_MEM_SCRIPT := $(SRC_PATH)/targets/$(LD_MEM_SCRIPT)
LD_PLC_SCRIPT := $(SRC_PATH)/targets/$(LD_PLC_SCRIPT)

# clean up legacy options
ifeq ($(BIN_SUFFIX),0)
	BIN_SUFFIX =
endif
ifeq ($(CONFIG_FILE),0)
	CONFIG_FILE =
endif
ifeq ($(BOARD_FILE),0)
	BOARD_FILE =
endif

# prevent HILS build with AIMU
ifneq ($(HIL_SIM), 0)
	ifeq ($(BOARD_VER), 6)
		ifeq ($(DIMU_VER), 0)
			HIL_SIM = 0
		endif
	endif
endif

DIMU_VER := $(subst .,,$(DIMU_VER))

# literals
_space :=
_space +=
_comma := ,

# function to get Nth part of dot-delimted string, with optional default value (eg. version number)
# usage: $call( dotpart,N,string[,default])
dotpart = $(or $(word $1,$(subst ., ,$2)),$(value 3))

#
## Determine build version and final name for binary target
#

VERSION_FILE = $(SRC_PATH)/aq_version.h
ifeq ("$(wildcard $(VERSION_FILE))","")
	VERSION_FILE = $(SRC_PATH)/getbuildnum.h
endif
# get current version and build numbers
FW_VER := $(shell $(EXE_AWK) 'BEGIN { FS = "[ \"\t]+" }$$2 ~ /FI(MR|RM)WARE_VER(SION|_MAJ)/{print $$NF}' $(VERSION_FILE))
ifeq ($(findstring ., $(FW_VER)),)
	FW_VER := $(FW_VER).$(shell $(EXE_AWK) '$$2 ~ /FIMRWARE_VER_MIN/{print $$NF}' $(VERSION_FILE))
endif

BUILD_NUM := $(shell $(EXE_AWK) '$$2 ~ /BUILDNUMBER/{print $$NF}' $(SRC_PATH)/buildnum.h)
ifeq ($(INCR_BUILDNUM), 1)
	BUILD_NUM := $(shell $(EXE_EXPR) $(BUILD_NUM) + 1)
endif

# Resulting bin file names before extension
ifeq ($(DEBUG_BUILD), 1)
	# debug build gets a consistent name to simplify dev setup
	TARGET := $(BIN_NAME)-debug
	override INCR_BUILDNUM = 0
else
	TARGET := $(BIN_NAME)v$(FW_VER).$(BUILD_NUM)-hwv$(BOARD_VER).$(BOARD_REV)
	ifneq ($(DIMU_VER), 0)
		TARGET := $(TARGET)-dimu$(DIMU_VER)
	endif
	ifneq ($(QUATOS), 0)
		TARGET := $(TARGET)-quatos
	endif
	ifneq ($(HIL_SIM), 0)
		TARGET := $(TARGET)-hils
	endif
	ifneq ($(BIN_SUFFIX),)
		TARGET := $(TARGET)-$(BIN_SUFFIX)
	endif
endif

ifeq ($(TOOLCHAIN), CW)
	ifeq ($(CW_VERSION),)
		CW_VERSION := $(shell $(EXE_CAT) $(CC_PATH)/bin/version.txt)
	endif
	CW_VER_MAJ := $(call dotpart,1,$(CW_VERSION),2)
	CW_VER_MIN := $(call dotpart,2,$(CW_VERSION),1)
	CW_VER_REV := $(call dotpart,3,$(CW_VERSION),1)
endif

#
## Build tools specs and flags
#

# Compiler-specific paths
ifeq ($(TOOLCHAIN), CW)
	ifeq ($(CW_VER_MAJ), 2)
		CC_EABI ?= arm-unknown-eabi
	else
		CC_EABI ?= arm-none-eabi
	endif
	CC_BIN_PATH = $(CC_PATH)/gcc/$(CC_EABI)/bin
	CC_LIB_PATH = $(CC_PATH)/lib
	CC_INC_PATH = $(CC_PATH)/include
	CC_TOOL_PFX =
	CC = $(CC_BIN_PATH)/cc1
else
	CC_EABI ?= arm-none-eabi
	CC_BIN_PATH = $(CC_PATH)/bin
	CC_LIB_PATH =
	CC_INC_PATH =
	CC_TOOL_PFX = $(CC_EABI)-
	CC = $(CC_BIN_PATH)/$(CC_TOOL_PFX)gcc
endif
LD = $(CC_BIN_PATH)/$(CC_TOOL_PFX)ld
AS = $(CC_BIN_PATH)/$(CC_TOOL_PFX)as
OBJCP = $(CC_BIN_PATH)/$(CC_TOOL_PFX)objcopy
SIZE ?= $(CC_BIN_PATH)/$(CC_TOOL_PFX)size

# all include flags for the compiler
CC_INCLUDES ?=
ifneq ($(SRC_PATH),)
	CC_INCLUDES += -I$(SRC_PATH)
endif
CC_INCLUDES += -I$(SRC_PATH)/co_os
CC_INCLUDES += -I$(SRC_PATH)/drivers
CC_INCLUDES += -I$(SRC_PATH)/drivers/can
CC_INCLUDES += -I$(SRC_PATH)/drivers/disk
CC_INCLUDES += -I$(SRC_PATH)/drivers/usb
CC_INCLUDES += -I$(SRC_PATH)/math
CC_INCLUDES += -I$(SRC_PATH)/radio
CC_INCLUDES += -I$(SRC_PATH)/targets
CC_INCLUDES += -I$(STM32DRIVER_PATH)/inc
CC_INCLUDES += -I$(STM32CMSIS_PATH)/Include
CC_INCLUDES += -I$(STM32CMSIS_PATH)/Device/ST/STM32F4xx/Include
CC_INCLUDES += -I$(MAVLINK_PATH)
CC_INCLUDES += -I$(HIL_SIM_PATH)/include
ifneq ($(CC_INC_PATH),)
	CC_INCLUDES += -isystem$(CC_INC_PATH)
endif

# path hints for make
VPATH ?=
VPATH += $(CC_INCLUDES) $(STM32DRIVER_PATH)/src $(ARMDSPLIB_SRC)

# macro definitions to pass via compiler command line
#
CDEFS ?=
CDEFS += \
	-D__SIZEOF_WCHAR_T=4              \
	-D__ARM_ARCH_7EM__                \
	-D__ARM_ARCH_FPV4_SP_D16__        \
	-DSTM32F4XX                       \
	-D__SYSTEM_STM32F4XX              \
	-D__TARGET_PROCESSOR=$(MCU_VER)   \
	-D__TARGET_PROCESSOR_$(MCU_VER)   \
	-D__FPU_PRESENT=1                 \
	-DARM_MATH_CM4                    \
	-D__THUMB                         \
	-DNESTED_INTERRUPTS               \
	-DUSE_STDPERIPH_DRIVER            \
	-DINITIALIZE_STACK				  \
	-DSTARTUP_FROM_RESET              \
	-DBOARD_VERSION=$(BOARD_VER)      \
	-DBOARD_REVISION=$(BOARD_REV)     \
	-DDIMU_VERSION=$(DIMU_VER)

ifeq ($(MCU_VER),STM32F407VG)
	CDEFS += \
		-DSTM32F40_41xxx        \
		-DSTM32F407xx           \
		-D__VECTORS=\"STM32F40_41xxx.vec\"
endif
# else
ifeq ($(MCU_VER),STM32F427VG)
	CDEFS += \
		-DSTM32F427_437xx        \
		-DSTM32F427xx           \
		-D__VECTORS=\"STM32F427_437xx.vec\"
endif

ifeq ($(TOOLCHAIN), CW)
	CDEFS += \
		-D__CROSSWORKS_ARM  \
		-D__CROSSWORKS_MAJOR_VERSION=$(CW_VER_MAJ)  \
		-D__CROSSWORKS_MINOR_VERSION=$(CW_VER_MIN)  \
		-D__CROSSWORKS_REVISION=$(CW_VER_REV)         
endif

ifneq ($(CONFIG_FILE),)
	CDEFS += -DCONFIG_DEFAULTS_FILE=\"$(CONFIG_FILE)\"
endif
ifneq ($(BOARD_FILE),)
	CDEFS += -DBOARD_HEADER_FILE=\"$(BOARD_FILE)\"
endif

# MCU-specific flags
MCUFLAGS ?= \
	-mcpu=cortex-m4 \
	-mfpu=fpv4-sp-d16 \
	-mfloat-abi=hard \
	-mthumb

# compiler flags
CFLAGS ?=
CFLAGS += \
	$(MCUFLAGS) \
	-mlittle-endian \
	-mtp=soft  \
	-std=gnu99 \
	-ggdb \
	-Wall \
	-Wdouble-promotion \
	-Winline \
	-fsingle-precision-constant	\
	-fshort-enums \
	-finline-functions \
	-fno-dwarf2-cfi-asm \
	-fno-common \
	-ffunction-sections \
	-fdata-sections \
	-fmessage-length=0 \
	--param large-function-insns=5400

ifeq ($(TOOLCHAIN), CW)
	CFLAGS += \
		-quiet \
		-nostdinc \
		-fno-builtin \
		-MD $(basename $@).d
else
	CFLAGS += -S -MD
endif

CFLAGS += $(CC_INCLUDES)
CFLAGS += $(CDEFS)
CFLAGS += $(CC_ADD_VARS)

# assembler options
ASMFLAGS ?=
ASMFLAGS += \
	$(MCUFLAGS) \
	--traditional-format \
	-EL

# linker options
LDFLAGS ?=
LDFLAGS += \
	-defsym=__HEAPSIZE__=$(HEAP_SIZE)  \
	-defsym=__STACKSIZE__=$(STACK_SIZE)  \
	-T$(LD_MEM_SCRIPT)  \
	-T$(LD_PLC_SCRIPT)  \
	-Map=$(OBJ_PATH)/autoquad.map  \
	-ereset_handler  \
	--omagic  \
	--fatal-warnings  \
	--gc-sections  \
	-u_vectors  \
	-EL  \
	-X  \
	--cref #--verbose
	
# declare printf/scanf variants to use
ifeq ($(PRINTF_FLOAT),0)
	ifeq ($(TOOLCHAIN), CW)
		LDFLAGS += -defsym=__vfprintf=__vfprintf_long -u__vfprintf_long
		#LDFLAGS += -defsym=__vfscanf=__vfscanf__long -u__vfscanf_long
	endif
else  # add float support
	ifeq ($(TOOLCHAIN), CW)
		ifeq ($(CW_VER_MAJ), 2)
			LDFLAGS += -defsym=__vfprintf=__vfprintf_double_long_long -u__vfprintf_double_long_long
			#LDFLAGS += -defsym=__vfscanf=__vfscanf_double_long_long -u__vfscanf_double_long_long
		else
			LDFLAGS += -defsym=__vfprintf=__vfprintf_float_long_long
			#LDFLAGS += -defsym=__vfscanf=__vfscanf_float_long_long_cc
		endif
	else  # GAE
		LDFLAGS += -u_printf_float #-u_scanf_float 
	endif
endif

# required toolchain libs
LDLIBS ?=
ifeq ($(TOOLCHAIN), CW)
	# ! These are proprietary Rowley libraries, approved for personal use with the AQ project (see http://forum.autoquad.org/viewtopic.php?f=31&t=44&start=50#p8476 )
	ARM_LIB_QUAL ?= _v7em_fpv4_sp_d16_hard_t_le_eabi
	LDLIBS += $(addsuffix $(ARM_LIB_QUAL), -lm -lc -ldebugio)
	ifeq ($(CW_VER_MAJ), 2)
		LDLIBS += $(addsuffix $(ARM_LIB_QUAL), -lc_user_libc -lc_targetio_impl)
		LDFLAGS += -defsym=__do_debug_operation=__do_debug_operation_mempoll -u__do_debug_operation_mempoll
	else
		LDLIBS += $(addsuffix $(ARM_LIB_QUAL), -ldebugio_mempoll)
		LDLIBS += $(addsuffix $(ARM_LIB_QUAL).o, -l:libvfprintf)  # -l:libvfscanf
	endif
else  # GAE
	LDLIBS += -lm
	# lib spec is only used when linking with gcc command
	LIBSPEC ?= -nostartfiles -specs=nosys.specs -specs=nano.specs
endif

LIBPATHS ?=
ifneq ($(CC_LIB_PATH),)
	LIBPATHS += -L$(CC_LIB_PATH)
endif


# Conditional options

# build flags/defs for debug vs. release
ifeq ($(DEBUG_BUILD), 1)
	CFLAGS += -Og -g3
	CDEFS += -DDEBUG -DUSE_FULL_ASSERT
else  # Release build
	CFLAGS += -O2 -g2
	CDEFS += -DNDEBUG
endif

# CMSIS DSP Library in /CMSIS/Lib (only when not building from source)
ifeq ($(BUILD_CMSIS_SRC), 0)
	LDLIBS += -larm_cortexM4lf_math
	LIBPATHS += -L$(ARMDSPLIB_PATH)
endif

ifneq ($(QUATOS), 0)
	ifeq ($(QUATOS), 1)
		LIBPATHS += -L$(QUATOS_PATH)
		LDLIBS += -l:quatos.a
	endif
	CFLAGS += -DHAS_QUATOS
endif

ifneq ($(HIL_SIM), 0)
	ifeq ($(HIL_SIM), 1)
		LIBPATHS += -L$(HIL_SIM_PATH)
		LDLIBS += -l:hilSim.a
	endif
	CFLAGS += -DHAS_HIL_SIM_MP
endif

# end of build tools options


#
## What to build
#

# Objects to create (correspond to .c source to compile)

# Target hardware-specific in src/targets
AQ_OBJ += \
	targets/STM32_Startup.o \
	targets/system_stm32f4xx.o \
	targets/thumb_crt0.o

# core code in src/
AQ_OBJ += \
	alt_ukf.o aq_init.o aq_mavlink.o aq_timer.o \
	calib.o comm.o command.o compass.o config.o control.o \
	d_imu.o debug.o esc32.o filer.o gimbal.o gps.o imu.o logger.o \
	main_ctl.o motors.o nav.o nav_ukf.o pid.o rc.o run.o \
	signaling.o supervisor.o \
	telem_sPort.o telemetry.o util.o

# Math lib
AQ_OBJ += \
	math/algebra.o \
	math/rotations.o \
	math/srcdkf.o 

# RC radio handlers
AQ_OBJ += \
	radio/dsm.o \
	radio/futaba.o \
	radio/grhott.o \
	radio/mlinkrx.o \
	radio/ppm.o \
	radio/radio.o  \
	radio/spektrum.o 

# CoOS in src/co_os/
AQ_OBJ += $(addprefix co_os/, \
	arch.o core.o event.o flag.o kernelHeap.o mbox.o mm.o mutex.o \
	port.o queue.o sem.o serviceReq.o task.o time.o timer.o utility.o \
)

# CAN drivers and functions
AQ_OBJ += \
	drivers/can/can.o \
	drivers/can/canCalib.o \
	drivers/can/canOSD.o \
	drivers/can/canSensors.o \
	drivers/can/canUart.o

# Disk I/O and FatFS drivers
AQ_OBJ += \
	drivers/disk/ff.o \
	drivers/disk/sdio.o

# Target hardware-level drivers in src/drivers
AQ_OBJ += $(addprefix drivers/, \
	1wire.o adc.o analog.o cyrf6936.o eeprom.o ext_irq.o digital.o \
	flash.o fpu.o  hmc5983.o lis3mdl.o max21100.o mpu6000.o mpu9250.o ms5611.o \
	pwm.o rcc.o rtc.o serial.o spi.o ublox.o \
)

# USB drivers in src/drivers/usb/
AQ_OBJ += $(addprefix drivers/usb/, \
	usb.o usb_bsp.o usb_core.o usb_dcd.o usb_dcd_int.o \
	usbd_core.o  usbd_desc.o  usbd_ioreq.o  usbd_req.o usbd_storage_msd.o \
	usbd_cdc_msc_core.o usbd_msc_bot.o usbd_msc_data.o usbd_msc_scsi.o \
)

# STM32 drivers from STM32F4xx_StdPeriph_Driver/src/
LIB_OBJ += $(addprefix $(STM32DRIVER_PATH)/src/, \
	misc.o \
	$(addprefix stm32f4xx_, \
		adc.o can.o dbgmcu.o dma.o exti.o flash.o gpio.o \
		pwr.o rcc.o rtc.o sdio.o spi.o syscfg.o tim.o usart.o \
	) \
)

# ARM drivers from CMSIS/DSP_Lib/Source/
# by default we use the pre-built library CMSIS/Lib/libarm_cortexM4lf_math.a
ifeq ($(BUILD_CMSIS_SRC), 1)
	LIB_OBJ += $(addprefix $(ARMDSPLIB_SRC)/, \
		BasicMathFunctions/arm_scale_f32.o \
		MatrixFunctions/arm_mat_init_f32.o \
		MatrixFunctions/arm_mat_inverse_f32.o \
		MatrixFunctions/arm_mat_trans_f32.o \
		MatrixFunctions/arm_mat_mult_f32.o \
		MatrixFunctions/arm_mat_add_f32.o \
		MatrixFunctions/arm_mat_sub_f32.o \
		StatisticsFunctions/arm_mean_f32.o \
		StatisticsFunctions/arm_std_f32.o \
		SupportFunctions/arm_fill_f32.o \
		SupportFunctions/arm_copy_f32.o \
	)
endif


# combine objects
ALL_OBJ = $(addprefix $(OBJ_PATH)/, $(addprefix $(SRC_PATH)/, $(AQ_OBJ)) $(LIB_OBJ) $(EXTRA_OBJECTS))

# dependency files generated by previous make runs
DEPS := $(ALL_OBJ:.o=.d)

# Additional target(s) to build based on conditionals
#
EXTRA_TARGET_DEPS ?= #makefile-debug
ifeq ($(INCR_BUILDNUM), 1)
	EXTRA_TARGET_DEPS = BUILDNUMBER
endif


#
## Misc. config
#

# command to execute (later, if necessary) for increasing build number in buildnum.h
CMD_BUILDNUMBER = $(shell $(EXE_AWK) '$$2 ~ /BUILDNUMBER/{ $$NF=$$NF+1 } 1' $(SRC_PATH)/buildnum.h > $(SRC_PATH)/tmp_buildnum.h && $(EXE_MV) $(SRC_PATH)/tmp_buildnum.h $(SRC_PATH)/buildnum.h)

# target memory locations and sizes in KB (from ld scripts)
MEM_START_FLASH = 0x8000000
MEM_START_CCM   = 0x10000000
MEM_START_SRAM1 = 0x20000000
MEM_START_SRAM2 = 0x2001c000
MEM_START_SRAM3 = 0xFFFFFFFF

MEM_SIZE_FLASH = 1024
MEM_SIZE_CCM   = 64
MEM_SIZE_SRAM1 = 112
MEM_SIZE_SRAM2 = 16
MEM_SIZE_SRAM3 = 0

ifeq ($(MCU_VER),STM32F427VG)
	MEM_START_SRAM3 = 0x20020000
	MEM_SIZE_SRAM3 = 64
endif

# script to run for reporting allocated memory sizes
CMD_SIZE_REPORT = `$(SIZE) -A -x $(BIN_PATH)/$(TARGET).elf | $(EXE_AWK) -n '\
	BEGIN { \
		c=0; r=0; r2=0; r3=0; f=0; \
		printf("\n---- Size report ----\n\nSection Details:\n%-10s\t%7s\t\t%10s\t%s\n", "section", "size(B)", "addr", "loc") \
	} \
	NR > 2 && $$2 != 0 && $$3 != 0x0 && $$3 != "" { \
		printf("%-10s\t%7d\t\t0x%08x\t", $$1, $$2, $$3); \
		if ($$1 == ".data" || $$1 == ".rodata") {f += $$2; print "F"}   \
		else if ($$3 >= $(MEM_START_SRAM3)) {r3 += $$2; print "S3"} \
		else if ($$3 >= $(MEM_START_SRAM2)) {r2 += $$2; print "S2"} \
		else if ($$3 + $$2 >= $(MEM_START_SRAM2)) {t = $$3 + $$2 - $(MEM_START_SRAM2); r2 += t; r += $$2 - t; print "S1+S2"} \
		else if ($$3 + $$2 >= $(MEM_START_SRAM3)) {t = $$3 + $$2 - $(MEM_START_SRAM3); r3 += t; r2 += $$2 - t; print "S2+S3"} \
		else if ($$3 >= $(MEM_START_SRAM1)) {r += $$2; print "S1"}  \
		else if ($$3 >= $(MEM_START_CCM))   {c += $$2; print "C"}   \
		else if ($$3 >= $(MEM_START_FLASH)) {f += $$2; print "F"}   \
	} \
	END { \
		printf("\nTotals: %10s\t  usage\tof ttl\tKB free\n Flash: %10.2f\t%6.2f%\t%6d\t%7.2f\n   CCM: %10.2f\t%6.2f%\t%6d\t%7.2f\n SRAM1: %10.2f\t%6.2f%\t%6d\t%7.2f\n SRAM2: %10.2f\t%6.2f%\t%6d\t%7.2f\n", "KB", \
			f/1024, f/($(MEM_SIZE_FLASH)*1024)*100, $(MEM_SIZE_FLASH), $(MEM_SIZE_FLASH) - f/1024, \
			c/1024, c/($(MEM_SIZE_CCM)*1024)*100, $(MEM_SIZE_CCM), $(MEM_SIZE_CCM) - c/1024, \
			r/1024, r/($(MEM_SIZE_SRAM1)*1024)*100, $(MEM_SIZE_SRAM1), $(MEM_SIZE_SRAM1) - r/1024, \
			r2/1024, r2/($(MEM_SIZE_SRAM2)*1024)*100, $(MEM_SIZE_SRAM2), $(MEM_SIZE_SRAM2) - r2/1024 ); \
		if ($(MEM_SIZE_SRAM3) > 0) {  \
			printf(" SRAM3: %10.2f\t%6.2f%\t%6d\t%7.2f\n", r3/1024, r3/($(MEM_SIZE_SRAM3)*1024)*100, $(MEM_SIZE_SRAM3), $(MEM_SIZE_SRAM3) - r3/1024 ); \
		} \
	}'`


#
## Target definitions
#

.PHONY: all elf hex bin clean-all clean clean-bin clean-pack pack pack-hex pack-bin size swd dfu sfl makefile-debug BUILDNUMBER $(OBJ_PATH)
.IGNORE: size 

all: elf hex bin
elf: $(BIN_PATH)/$(TARGET).elf
hex: $(BIN_PATH)/$(TARGET).hex
bin: $(BIN_PATH)/$(TARGET).bin

clean-all: clean clean-bin clean-pack

clean:
	-$(EXE_RM) -fr $(OBJ_PATH)
	
clean-bin:
	-$(EXE_RM) -f $(BIN_PATH)/*.elf
	-$(EXE_RM) -f $(BIN_PATH)/*.bin
	-$(EXE_RM) -f $(BIN_PATH)/*.hex

clean-pack:
	-$(EXE_RM) -f $(BIN_PATH)/*.$(ZIP_EXT)
	
pack: pack-hex pack-bin


# include auto-generated depenency targets
ifeq ($(findstring clean, $(MAKECMDGOALS)),)
-include $(DEPS)
endif

$(OBJ_PATH)/%.o: %.c
	@$(EXE_MKDIR) -p $(@D)
	@echo "## Compiling $< -> $@ ##"
	$(CC) $(CFLAGS) -MQ $@ $< -o $(basename $@).s
	@echo "## Assembling --> $@ ##"
	$(AS) $(ASMFLAGS) $(basename $@).s -o $@
#	@$(EXE_RM) -f $(basename $@).s

$(OBJ_PATH)/%.o: %.S
	@$(EXE_MKDIR) -p $(@D)
	@echo "## Compiling $< -> $@ ##"
	$(CC) $(CFLAGS) -MQ $@ -E $< -o $(basename $@).s
	@echo "## Assembling --> $@ ##"
	$(AS) $(ASMFLAGS) $(basename $@).s -g -gdwarf-4 -o $@
#	@$(EXE_RM) -f $(basename $@).s

$(BIN_PATH)/$(TARGET).elf: $(EXTRA_TARGET_DEPS) $(ALL_OBJ) $(LD_MEM_SCRIPT) $(LD_PLC_SCRIPT)
	@echo
	@echo "## Linking --> $@ ##"
ifeq ($(TOOLCHAIN), CW)
	$(LD) $(LDFLAGS) $(LIBPATHS) -o $@ --start-group $(ALL_OBJ) $(LDLIBS) --end-group
else
	$(CC) $(MCUFLAGS) $(LIBPATHS) $(LIBSPEC) -o $@ -Wl,$(subst $(_space),$(_comma),$(strip $(LDFLAGS) --start-group $(ALL_OBJ) $(LDLIBS) --end-group))
endif
	@if $(EXE_TEST) -f $(SIZE); then echo "${CMD_SIZE_REPORT}"; else echo ; echo "$(SIZE) command not found!"; fi

$(BIN_PATH)/$(TARGET).bin: $(BIN_PATH)/$(TARGET).elf
	@echo
	@echo "## Objcopy $< --> $@ ##"
	$(OBJCP) -O binary $< $@

$(BIN_PATH)/$(TARGET).hex: $(BIN_PATH)/$(TARGET).elf
	@echo
	@echo "## Objcopy $< --> $@ ##"
	$(OBJCP) -O ihex $< $@

BUILDNUMBER :
	@echo
	@echo "Incrementing Build Number"
	$(CMD_BUILDNUMBER)
	@echo

size:
	@if $(EXE_TEST) -f $(SIZE) AND $(EXE_TEST) -f $(BIN_PATH)/$(TARGET).elf; then echo "${CMD_SIZE_REPORT}"; else echo ; echo "$(SIZE) or elf file not found!"; fi

makefile-debug:
	@echo
	@echo AQ_OBJ = $(AQ_OBJ)
	@echo
	@echo LIB_OBJ = $(LIB_OBJ)
	@echo
	@echo LIBPATHS = $(LIBPATHS)
	@echo
	@echo LDLIBS = $(LDLIBS)

pack-hex pack-bin: pack-% : %
	@echo
	@echo "Compressing $< files... "
	$(EXE_ZIP) $(BIN_PATH)/$(TARGET).$(ZIP_EXT) $(BIN_PATH)/$(TARGET).$<


swd: bin
ifeq ($(SWD_UTIL),st-flash)
	-$(SWD_UTIL) --reset write $(BIN_PATH)/$(TARGET).bin 0x8000000
else  # ST-LINK_CLI
	-$(SWD_UTIL) -c SWD -P $(BIN_PATH)/$(TARGET).bin 0x8000000 $(if $(findstring 1,$(FLASH_VRFY)),-V,) -Rst -Q
endif

dfu: bin
	-$(DFU_UTIL) -a 0 -d 0483:df11 -s 0x08000000:leave -R -D $(BIN_PATH)/$(TARGET).bin

sfl: bin
	-$(SER_UTIL) -b 115200 -w $(BIN_PATH)/$(TARGET).bin -s 0x08000000 $(if $(findstring 1,$(FLASH_VRFY)),-v,) $(SER_DEV)
