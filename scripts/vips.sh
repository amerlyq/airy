#!/bin/bash

width=`header -f Xsize $1`
height=`header -f Ysize $1`

width=$((width - 200))
height=$((height - 200))

set -x

vips im_extract_area $1 t1.v 100 100 $width $height
vips im_affinei_all t1.v t2.v bilinear 0.9 0 0 0.9 0 0
cat > mask.con <<EOF
3 3 8 0
-1 -1 -1
-1 16 -1
-1 -1 -1
EOF
vips im_conv t2.v $2 mask.con
rm t1.v t2.v mask.con