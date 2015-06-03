##
##
##  Attract-Mode frontend
##  Copyright (C) 2013 Andrew Mickelson
##
##  This file is part of Attract-Mode.
##
##  Attract-Mode is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  Attract-Mode is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with Attract-Mode.  If not, see <http://www.gnu.org/licenses/>.
##
##
###############################
#
# BUILD CONFIGURATION OPTIONS:
#
# Uncomment next line to disable movie support (i.e. no FFmpeg).
#NO_MOVIE=1
#
# Uncomment next line to disable network support (i.e. no SFML Network).
#NO_NET=1
#
# By default, if FontConfig gets enabled we link against the system's expat 
# library (because FontConfig uses expat too).  If FontConfig is not used
# then Attract-Mode is statically linked to its own version of expat.
# Uncomment next line to always link to Attract-Mode's version of expat.
#BUILD_EXPAT=1
#
# Uncomment next line for Windows static cross-compile build (mxe)
#WINDOWS_STATIC=1
#
# Uncomment the next line if you wish to use SFML to load images instead
# of FFmpeg (has no effect if NO_MOVIE=1)
#SFML_IMAGES=1
###############################

#FE_DEBUG=1

CC=$(CROSS)gcc
CPP=$(CROSS)g++
CFLAGS=
PKG_CONFIG=$(CROSS)pkg-config
AR=$(CROSS)ar
ARFLAGS=rc
RM=rm -f
MD=mkdir

prefix=/usr/local
datarootdir=$(prefix)/share
datadir=$(datarootdir)
exec_prefix=$(prefix)
bindir=$(exec_prefix)/bin

DATA_PATH=$(datadir)/attract/
EXE_BASE=attract
EXE_EXT=
OBJ_DIR=obj
SRC_DIR=src
EXTLIBS_DIR=extlibs
FE_FLAGS=

_DEP =\
	fe_base.hpp \
	fe_util.hpp \
	fe_util_sq.hpp \
	fe_info.hpp \
	fe_input.hpp \
	fe_romlist.hpp \
	fe_xml.hpp \
	fe_settings.hpp \
	fe_config.hpp \
	fe_presentable.hpp \
	fe_present.hpp \
	sprite.hpp \
	fe_image.hpp \
	fe_sound.hpp \
	fe_shader.hpp \
	fe_overlay.hpp \
	fe_window.hpp \
	tp.hpp \
	fe_text.hpp \
	fe_listbox.hpp \
	fe_vm.hpp \
	fe_icon.hpp

_OBJ =\
	fe_base.o \
	fe_util.o \
	fe_util_sq.o \
	fe_info.o \
	fe_input.o \
	fe_romlist.o \
	fe_xml.o \
	fe_settings.o \
	fe_build.o \
	fe_config.o \
	fe_presentable.o \
	fe_present.o \
	sprite.o \
	fe_image.o \
	fe_sound.o \
	fe_shader.o \
	fe_overlay.o \
	fe_window.o \
	tp.o \
	fe_text.o \
	fe_listbox.o \
	fe_vm.o \
	main.o

ifneq ($(FE_WINDOWS_COMPILE),1)
 #
 # Test OS to set some defaults
 #
 ifeq ($(OS),Windows_NT)
  #
  # Windows
  #
  FE_WINDOWS_COMPILE=1
 else
  UNAME = $(shell uname -a)
  ifeq ($(firstword $(filter Darwin,$(UNAME))),Darwin)
   #
   # Mac OS X
   #
   _DEP += fe_util_osx.hpp
   _OBJ += fe_util_osx.o
   LIBS += -framework Cocoa

   FE_MACOSX_COMPILE=1
  else
   #
   # Test for Raspberry Pi
   #
   ifneq ("$(wildcard /opt/vc/include/bcm_host.h)","")
    FE_RPI=1
   else
    #
    # Test for Xinerama...
    #
    ifeq ($(shell $(PKG_CONFIG) --exists xinerama && echo "1" || echo "0"), 1)
     USE_XINERAMA=1
    endif
   endif
  endif
 endif
endif

#
# Deal with SFML
#
ifeq ($(WINDOWS_STATIC),1)
 LIBS += $(shell $(PKG_CONFIG) --static --libs sfml)
 CFLAGS += -DSFML_STATIC $(shell $(PKG_CONFIG) --static --cflags sfml)
 FE_WINDOWS_COMPILE=1

else

 ifeq ($(NO_NET),1)
  LIBS += -lsfml-graphics \
	-lsfml-window \
	-lsfml-system
  FE_FLAGS += -DNO_NET
 else
  LIBS += -lsfml-graphics \
	-lsfml-window \
	-lsfml-network \
	-lsfml-system
 endif
endif

ifneq ($(NO_NET),1)
 _DEP += fe_net.hpp
 _OBJ += fe_net.o
endif

ifeq ($(FE_WINDOWS_COMPILE),1)
 CFLAGS += -mconsole
 EXE_EXT = .exe
else
 CFLAGS += -DDATA_PATH=\"$(DATA_PATH)\"
endif

#
# Check whether optional libs should be enabled
#
ifneq ($(FE_WINDOWS_COMPILE),1)
 ifeq ($(shell $(PKG_CONFIG) --exists fontconfig && echo "1" || echo "0"), 1)
 USE_FONTCONFIG=1
 endif
endif

ifeq ($(shell $(PKG_CONFIG) --exists libswresample && echo "1" || echo "0"), 1)
 USE_SWRESAMPLE=1
endif

ifeq ($(shell $(PKG_CONFIG) --exists libavresample && echo "1" || echo "0"), 1)
 USE_AVRESAMPLE=1
endif

#
# Now process the various settings...
#
ifeq ($(FE_DEBUG),1)
 CFLAGS += -g -Wall
 FE_FLAGS += -DFE_DEBUG
else
 CFLAGS += -O2 -s
endif

ifeq ($(FE_RPI),1)
 FE_FLAGS += -DFE_RPI
endif

ifeq ($(USE_XINERAMA),1)
 FE_FLAGS += -DUSE_XINERAMA
 LIBS += -lX11 -lXinerama
endif

ifeq ($(USE_FONTCONFIG),1)
 FE_FLAGS += -DUSE_FONTCONFIG
 TEMP_LIBS += fontconfig
else
 BUILD_EXPAT=1
endif

ifeq ($(NO_MOVIE),1)
 FE_FLAGS += -DNO_MOVIE
 LIBS += -lsfml-audio
 AUDIO =
else
 TEMP_LIBS += libavformat libavcodec libavutil libswscale

 ifeq ($(FE_MACOSX_COMPILE),1)
  LIBS += -framework OpenAL
 else
  TEMP_LIBS += openal
 endif

 ifeq ($(USE_SWRESAMPLE),1)
  TEMP_LIBS += libswresample
  FE_FLAGS += -DUSE_SWRESAMPLE
 else
  ifeq ($(USE_AVRESAMPLE),1)
  TEMP_LIBS += libavresample
  FE_FLAGS += -DUSE_AVRESAMPLE
  endif
 endif 

 _DEP += media.hpp
 _OBJ += media.o

 ifeq ($(SFML_IMAGES),1)
  FE_FLAGS += -DSFML_IMAGES
 endif

 CFLAGS += -I$(EXTLIBS_DIR)/audio/include
 AUDIO = $(OBJ_DIR)/libaudio.a
endif

LIBS += $(shell $(PKG_CONFIG) --libs $(TEMP_LIBS))
CFLAGS += $(shell $(PKG_CONFIG) --cflags $(TEMP_LIBS))

EXE = $(EXE_BASE)$(EXE_EXT)

ifeq ($(BUILD_EXPAT),1)
 CFLAGS += -I$(EXTLIBS_DIR)/expat
 EXPAT = $(OBJ_DIR)/libexpat.a
else
 LIBS += -lexpat
 EXPAT =
endif

CFLAGS += -I$(EXTLIBS_DIR)/squirrel/include -I$(EXTLIBS_DIR)/sqrat/include
SQUIRREL = $(OBJ_DIR)/libsquirrel.a $(OBJ_DIR)/libsqstdlib.a

CFLAGS += -I$(EXTLIBS_DIR)/manymouse
MANYMOUSE = $(OBJ_DIR)/libmanymouse.a

OBJ = $(patsubst %,$(OBJ_DIR)/%,$(_OBJ))
DEP = $(patsubst %,$(SRC_DIR)/%,$(_DEP))

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(DEP) | $(OBJ_DIR)
	$(CPP) -c -o $@ $< $(CFLAGS) $(FE_FLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.mm $(DEP) | $(OBJ_DIR)
	$(CC) -c -o $@ $< $(CFLAGS) $(FE_FLAGS)

$(EXE): $(OBJ) $(EXPAT) $(SQUIRREL) $(AUDIO) $(MANYMOUSE)
	$(CPP) -o $@ $^ $(CFLAGS) $(FE_FLAGS) $(LIBS)

.PHONY: clean

.PHONY: install

$(OBJ_DIR):
	$(MD) $@

#
# Expat Library
#
EXPAT_OBJ_DIR = $(OBJ_DIR)/expat

EXPATOBJS = \
	$(EXPAT_OBJ_DIR)/xmlparse.o \
	$(EXPAT_OBJ_DIR)/xmlrole.o \
	$(EXPAT_OBJ_DIR)/xmltok.o

$(OBJ_DIR)/libexpat.a: $(EXPATOBJS) | $(OBJ_DIR)
	$(AR) $(ARFLAGS) $@ $(EXPATOBJS)

$(EXPAT_OBJ_DIR)/%.o: $(EXTLIBS_DIR)/expat/%.c | $(EXPAT_OBJ_DIR)
	$(CC) -c $< -o $@ $(CFLAGS) -DHAVE_MEMMOVE

$(EXPAT_OBJ_DIR):
	$(MD) $@

#
# ManyMouse Library
#
MANYMOUSE_FLAGS = -fno-exceptions -fno-rtti -fno-strict-aliasing
MANYMOUSE_OBJ_DIR = $(OBJ_DIR)/manymouse

MANYMOUSE_OBJS= \
	$(MANYMOUSE_OBJ_DIR)/linux_evdev.o \
	$(MANYMOUSE_OBJ_DIR)/macosx_hidmanager.o \
	$(MANYMOUSE_OBJ_DIR)/macosx_hidutilities.o \
	$(MANYMOUSE_OBJ_DIR)/manymouse.o \
	$(MANYMOUSE_OBJ_DIR)/windows_wminput.o \
	$(MANYMOUSE_OBJ_DIR)/x11_xinput2.o

$(OBJ_DIR)/libmanymouse.a: $(MANYMOUSE_OBJS) | $(MANYMOUSE_OBJ_DIR)
	$(AR) $(ARFLAGS) $@ $(MANYMOUSE_OBJS)

$(MANYMOUSE_OBJ_DIR)/%.o: $(EXTLIBS_DIR)/manymouse/manymouse/%.c | $(MANYMOUSE_OBJ_DIR)
	$(CC) -c -o $@ $< $(CFLAGS) $(MANYMOUSE_FLAGS)

$(MANYMOUSE_OBJ_DIR):
	$(MD) $@

#
# Squirrel Library
#
SQUIRREL_FLAGS = -fno-exceptions -fno-rtti -fno-strict-aliasing
SQUIRREL_OBJ_DIR = $(OBJ_DIR)/squirrel

SQUIRRELOBJS= \
	$(SQUIRREL_OBJ_DIR)/sqapi.o \
	$(SQUIRREL_OBJ_DIR)/sqbaselib.o \
	$(SQUIRREL_OBJ_DIR)/sqfuncstate.o \
	$(SQUIRREL_OBJ_DIR)/sqdebug.o \
	$(SQUIRREL_OBJ_DIR)/sqlexer.o \
	$(SQUIRREL_OBJ_DIR)/sqobject.o \
	$(SQUIRREL_OBJ_DIR)/sqcompiler.o \
	$(SQUIRREL_OBJ_DIR)/sqstate.o \
	$(SQUIRREL_OBJ_DIR)/sqtable.o \
	$(SQUIRREL_OBJ_DIR)/sqmem.o \
	$(SQUIRREL_OBJ_DIR)/sqvm.o \
	$(SQUIRREL_OBJ_DIR)/sqclass.o

$(OBJ_DIR)/libsquirrel.a: $(SQUIRRELOBJS) | $(SQUIRREL_OBJ_DIR)
	$(AR) $(ARFLAGS) $@ $(SQUIRRELOBJS)

$(SQUIRREL_OBJ_DIR)/%.o: $(EXTLIBS_DIR)/squirrel/squirrel/%.cpp | $(SQUIRREL_OBJ_DIR)
	$(CPP) -c $< -o $@ $(CFLAGS) $(SQUIRREL_FLAGS) 

$(SQUIRREL_OBJ_DIR):
	$(MD) $@

#
# Squirrel libsqstdlib
#
SQSTDLIB_OBJ_DIR = $(OBJ_DIR)/sqstdlib

SQSTDLIBOBJS= \
	$(SQSTDLIB_OBJ_DIR)/sqstdblob.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdio.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdstream.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdmath.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdstring.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdaux.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdsystem.o \
	$(SQSTDLIB_OBJ_DIR)/sqstdrex.o

$(OBJ_DIR)/libsqstdlib.a: $(SQSTDLIBOBJS) | $(SQSTDLIB_OBJ_DIR)
	$(AR) $(ARFLAGS) $@ $(SQSTDLIBOBJS)

$(SQSTDLIB_OBJ_DIR)/%.o: $(EXTLIBS_DIR)/squirrel/sqstdlib/%.cpp | $(SQSTDLIB_OBJ_DIR)
	$(CPP) -c $< -o $@ $(CFLAGS) $(SQUIRREL_FLAGS) 

$(SQSTDLIB_OBJ_DIR):
	$(MD) $@

#
# Audio
#
AUDIO_OBJ_DIR = $(OBJ_DIR)/audiolib

AUDIOOBJS= \
	$(AUDIO_OBJ_DIR)/ALCheck.o \
	$(AUDIO_OBJ_DIR)/AudioDevice.o \
	$(AUDIO_OBJ_DIR)/Listener.o \
	$(AUDIO_OBJ_DIR)/SoundSource.o \
	$(AUDIO_OBJ_DIR)/SoundStream.o

$(OBJ_DIR)/libaudio.a: $(AUDIOOBJS) | $(AUDIO_OBJ_DIR)
	$(AR) $(ARFLAGS) $@ $(AUDIOOBJS)

$(AUDIO_OBJ_DIR)/%.o: $(EXTLIBS_DIR)/audio/Audio/%.cpp | $(AUDIO_OBJ_DIR)
	$(CPP) -c $< -o $@ $(CFLAGS)

$(AUDIO_OBJ_DIR):
	$(MD) $@

$(DATA_PATH):
	$(MD) $@

install: $(EXE) $(DATA_PATH)
	cp $(EXE) $(bindir)
	cp -r config/* $(DATA_PATH)

smallclean:
	-$(RM) $(OBJ_DIR)/*.o *~ core

clean:
	-$(RM) $(OBJ_DIR)/*.o $(EXPAT_OBJ_DIR)/*.o $(SQUIRREL_OBJ_DIR)/*.o $(SQSTDLIB_OBJ_DIR)/*.o $(AUDIO_OBJ_DIR)/*.o $(MANYMOUSE_OBJ_DIR)/*.o $(OBJ_DIR)/*.a *~ core
