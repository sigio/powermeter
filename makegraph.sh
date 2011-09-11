#!/bin/bash

ARGS=(
	-t "PowerUsage @ Site" \
        -v "Watt" \
        -w 600 -h 300 -y 100:5 --units-exponent 0 --full-size-mode \
        DEF:ppm=pulse.rrd:ppm:AVERAGE \
        "CDEF:Watt=ppm,2.5,60,*,*" \
        "CDEF:Low=Watt,0,750,LIMIT" \
        "CDEF:Mid=Watt,750,1500,LIMIT" \
        "CDEF:High=Watt,1500,3000,LIMIT" \
        "CDEF:VHigh=Watt,3000,15000,LIMIT" \
	-c BACK#000000 -c CANVAS#202020 -c MGRID#00ff00 -c GRID#008000 -c FONT#00ff00 \
	-c AXIS#00ff00 -c ARROW#00ff00 -c SHADEA#000000 -c SHADEB#000000
        AREA:Low#00ff00:"0 - 750" AREA:Mid#ffbf00:"750 - 1500" AREA:High#FF0000:"1500 - 3000" AREA:VHigh#ffffff:"> 3kW"
)

rrdtool graph powerusage-6h.png    "${ARGS[@]}" -s end-6h  -e now "GPRINT:Watt:LAST:Currently using\: %5.0lf %S Watts\n"
rrdtool graph powerusage.png       "${ARGS[@]}" -s end-2d  -e now "GPRINT:Watt:AVERAGE:Average usage\: %5.0lf %S Watts\n"
rrdtool graph powerusage-2wk.png   "${ARGS[@]}" -s end-14d -e now
rrdtool graph powerusage-1m.png   "${ARGS[@]}" -s end-1m -e now
