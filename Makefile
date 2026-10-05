FAS      ?= fas
FASFLAGS ?= -O2

SDL_CFLAGS := $(shell sdl-config --cflags)
SDL_LIBS   := $(shell sdl-config --libs)

CC      = gcc
CFLAGS  = -g -std=gnu99 $(SDL_CFLAGS) -MMD -MP
LIBS    = $(SDL_LIBS) -lSDL_mixer -lm

REF = reference/wolf4sdl
SRC = src
B   = build

FAS_INC := -I $(abspath $(REF)) $(patsubst -I%,-isystem %,$(filter -I%,$(SDL_CFLAGS))) $(filter -D%,$(SDL_CFLAGS))

vpath %.c $(REF) $(REF)/mame

SKIP        := sdl_winmain wl_atmos wl_cloudsky wl_dir3dspr wl_floorceiling wl_parallax wl_shade
MODULES     := $(filter-out $(SKIP),$(sort $(basename $(notdir $(wildcard $(REF)/*.c $(REF)/mame/*.c)))))
FAS_SOURCES := $(wildcard $(SRC)/*.fas)
FAS_MODULES := $(filter $(MODULES),$(basename $(notdir $(FAS_SOURCES))))
C_MODULES   := $(filter-out $(FAS_MODULES),$(MODULES))

C_OBJS   := $(C_MODULES:%=$(B)/c/%.o)
FAS_OBJS := $(FAS_MODULES:%=$(B)/fas/%.o)

stamp = $(shell mkdir -p $(B); echo '$(2)' | cmp -s - $(B)/$(1) || echo '$(2)' > $(B)/$(1))
$(call stamp,selection,$(abspath $(SRC)) $(FAS_MODULES) skip: $(SKIP))
$(call stamp,src-dir,$(abspath $(SRC)))

.PHONY: all run status clean

all: $(B)/wolf3d

$(B)/wolf3d: $(C_OBJS) $(FAS_OBJS) $(B)/selection
	$(CC) $(filter %.o,$^) -o $@ $(LIBS)

$(B)/c/%.o: %.c | $(B)/c
	$(CC) $(CFLAGS) -c $< -o $@

$(B)/fas/%.o: $(SRC)/%.fas $(FAS_SOURCES) $(B)/src-dir | $(B)/fas
	$(FAS) $(FASFLAGS) $(FAS_INC) -c $< -o $@

$(B) $(B)/c $(B)/fas:
	mkdir -p $@

run: all
	cd data && ../$(B)/wolf3d $(ARGS)

status:
	@echo "fas ($(words $(FAS_MODULES))/$(words $(MODULES))): $(FAS_MODULES)"
	@echo "c   ($(words $(C_MODULES))/$(words $(MODULES))): $(C_MODULES)"

clean:
	rm -rf $(B)

-include $(C_OBJS:.o=.d)
