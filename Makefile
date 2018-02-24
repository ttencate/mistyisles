SVGS=$(wildcard sprites/*.svg)
PNGS=$(patsubst %.svg,%.png,$(SVGS))

.PHONY: all
all: $(PNGS)

%.png: %.svg
	inkscape --without-gui --export-png=$@ --export-area-page $<
