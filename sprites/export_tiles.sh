#!/bin/sh

cd "$(dirname "$0")"

for b in land mist; do
  for s in '' l r t b lr tb lt lb rt rb lrt lrb ltb rtb lrtb; do
    case $s in
      *lr*) x=256;;
      *l*) x=384;;
      *r*) x=128;;
      *) x=0;;
    esac
    case $s in
      *tb*) y=256;;
      *t*) y=384;;
      *b*) y=128;;
      *) y=0;;
    esac
    w=128
    h=128
    f=0.264583332
    vbx=$(echo "scale=9;$x*$f" | bc)
    vby=$(echo "scale=9;$y*$f" | bc)
    vbw=$(echo "scale=9;$w*$f" | bc)
    vbh=$(echo "scale=9;$h*$f" | bc)
    out="${b}_$s.svg"
    echo "$out: $x $y $w $h"
    cat $b.svg \
      | sed "0,/width/{s/width=\"[^\"]*\"/width=\"$w\"/}" \
      | sed "0,/height/{s/height=\"[^\"]*\"/height=\"$h\"/}" \
      | sed "s/viewBox=\"[^\"]*\"/viewBox=\"$vbx $vby $vbw $vbh\"/" \
      > $out
  done
done
