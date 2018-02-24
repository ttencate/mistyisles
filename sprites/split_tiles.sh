#!/bin/bash

cd "$(dirname "$0")"

for id in '' l r lr t b tb lt rt lb rb lrt lrb ltb rtb lrtb; do
  inkscape --without-gui --export-id=land_$id --export-plain-svg=land_$id.svg tiles.svg
done
