SCAD_DIR := models/scad
STL_DIR  := models/stl

SCAD_FILES := $(wildcard $(SCAD_DIR)/*.scad)
STL_FILES  := $(patsubst $(SCAD_DIR)/%.scad,$(STL_DIR)/%.stl,$(SCAD_FILES))

.PHONY: all stl clean

all: stl

stl: $(STL_FILES)

$(STL_DIR)/%.stl: $(SCAD_DIR)/%.scad
	@mkdir -p $(STL_DIR)
	openscad -o $@ $<

clean:
	rm -f $(STL_DIR)/*.stl
