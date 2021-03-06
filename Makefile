PROJECT = main_test
MEMORY_PROFILER_PATCH_PATH :=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
#ROCKET_SIM_PATH := $(abspath $(dir $(MEMORY_PROFILER_PATCH_PATH)))
OS_TYPE := $(shell uname -s)
$(info Detected OS type is "$(OS_TYPE)")
###### makefile parameter ######
tm ?= ltalloc

###### C flags #####
CC = gcc
CFLAGS += -I$(MEMORY_PROFILER_PATCH_PATH)/include
##### C++ flags #####
CXX = g++

CXXFLAGS =-g \
	  -I$(MEMORY_PROFILER_PATCH_PATH)/include \
	  -Wall -pipe \
	  -O3 \
	  -march=native -mtune=native \
	  -pthread
CXXFLAGS += -fmessage-length=0 \
	    -fno-rtti -Wno-multichar \
	    -fvisibility-inlines-hidden \
	    -fno-stack-protector \
	    -fno-asynchronous-unwind-tables
##### C Source #####
CSOURCE += $(MEMORY_PROFILER_PATCH_PATH)/src/logging_system/ringbuffer.c
CSOURCE += $(MEMORY_PROFILER_PATCH_PATH)/src/main_test.c
##### C++ Source #####

CPPSOURCE += $(MEMORY_PROFILER_PATCH_PATH)/src/logging_system/malloc_count.cpp
	   


##### OBJECTS #####
OBJECTS = $(patsubst %.cpp, %.o, $(CPPSOURCE))
OBJECTS += $(patsubst %.c, %.o, $(CSOURCE))

##### Target malloc LIB#####
TARGET_MALLOC = $(tm)
##### LTALLOC #####
ifeq ($(TARGET_MALLOC),ltalloc)
  SHARED_LIBS_SOURCE = $(MEMORY_PROFILER_PATCH_PATH)/src/ltalloc.cpp
  SHARED_LIBS =  $(patsubst %.cpp, %.so, $(SHARED_LIBS_SOURCE))
  CXXFLAGS += -DLTALLOC
  CXXFLAGS_SHARELIB = -fPIC \
  		      		  -shared
##### LTALLOC END #####
else ifeq ($(TARGET_MALLOC),scalloc)
##### SCALLOC #####
  SHARED_LIBS_SOURCE = 
  ifeq ($(OS_TYPE), Darwin)
  	SHARED_LIBS = $(MEMORY_PROFILER_PATCH_PATH)/src/scalloc-1.0.0/out/Release/libscalloc.dylib
  else ifeq ($(OS_TYPE), Linux)
  	SHARED_LIBS = $(MEMORY_PROFILER_PATCH_PATH)/src/scalloc-1.0.0/out/Release/lib.target/libscalloc.so
  else
       @echo "Not syupport"
  endif
  CXXFLAGS += -DSCALLOC
##### SCALLOC END #####
else
##### Default is use glibc ######
  SHARED_LIBS_SOURCE =
  SHARED_LIBS =
  CXXFLAGS += -DGLIBC
endif

ifeq ($(OS_TYPE), Linux)
 CXX_LINUX_PLATFORM_FLAGS = -ldl \
                            -pthread
else
  CXX_LINUX_PLATFORM_FLAGS =
endif

all: $(PROJECT)

deps := $(OBJECTS:%.o=%.o.d)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -MMD -MF $@.d -c $<
%.o: %.c
	$(CC) -c $< -o $@ $(CFLAGS) $(CLIBS)
ifneq ($(TARGET_MALLOC),scalloc)
$(SHARED_LIBS): $(SHARED_LIBS_SOURCE)
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_SHARELIB) -o $@ $^
endif
$(PROJECT): $(OBJECTS) $(SHARED_LIBS)
	$(CXX) -o $@ $(OBJECTS) $(CXX_LINUX_PLATFORM_FLAGS)

run: $(PROJECT)
	./$(PROJECT)

	
clean:
	${RM} $(OBJECTS) $(PROJECT) $(deps) $(SHARED_LIBS)

distclean: clean
	$(RM) -rf $(BUILDDIR)
	$(RM) input_copy.asc tabout.asc doc.asc plot1.asc traj.asc dppl2f.dat

debug :
	@echo $(ROCKET_SIM_PATCH_PATH)
-include $(deps)

