#!/bin/sh

cd "$(dirname "$0")/sprites"

for s in '' l r t b lr tb lt lb rt rb lrt lrb ltb rtb lrtb; do
  case $s in
    *lr*) x=256;;
    *l*) x=384;;
    *r*) x=128;;
    *) x=0;;
  esac
  case $s in
    *tb*) y=128;;
    *t*) y=0;;
    *b*) y=256;;
    *) y=384;;
  esac
  inkscape --without-gui --export-png=land_$s.png --export-area=$x:$y:$((x+128)):$((y+128)) tiles.svg
done
