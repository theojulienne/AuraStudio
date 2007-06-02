CLARO_DIR=../claro
LIB_DIR=$(CLARO_DIR)/interface/d/

DERELICT_DIR=../derelict/

CFLAGS= -I/sw/include/cairo -I/opt/local/include/cairo -I/usr/local/include/cairo -g -I$(LIB_DIR)
LDFLAGS= -framework Cocoa  -dynamic -lcairo -L$(CLARO_DIR)/src/claro/base -L$(CLARO_DIR)/src/claro/graphics -lclaro-base -lclaro-graphics

APP_NAME=aurastudio

all: $(APP_NAME)

LIB_SRC=$(LIB_DIR)claro/core.d $(LIB_DIR)claro/base/*.d $(LIB_DIR)claro/graphics/*.d \
$(LIB_DIR)claro/graphics/widgets/*.d \
$(LIB_DIR)claro/graphics/cairo/*.d \
$(LIB_DIR)claro/graphics/cairooo/*.d

LIB_SRC+=$(DERELICT_DIR)DerelictGL/derelict/opengl/*.d \
$(DERELICT_DIR)DerelictGL/derelict/opengl/extension/*.d
CFLAGS+=-I$(DERELICT_DIR)DerelictGL/

BASE_SONAME=libclaro-base.dylib
GFX_SONAME=libclaro-graphics.dylib

TEST1_SRC=src/*.d $(LIB_SRC)
TEST1_OUT=$(APP_NAME)
$(APP_NAME): $(TEST1_SRC) $(BASE_SONAME) $(GFX_SONAME)
	gdc $(TEST1_SRC) -o $(TEST1_OUT) $(LDFLAGS) $(CFLAGS)

#BASE_SO=$(CLARO_DIR)/src/claro/base/$(BASE_SONAME)
#$(BASE_SONAME): $(BASE_SO)
#	cp $(BASE_SO) .
#
#GFX_SO=$(CLARO_DIR)/src/claro/graphics/$(GFX_SONAME)
#$(GFX_SONAME): $(GFX_SO)
#	cp $(GFX_SO) .
