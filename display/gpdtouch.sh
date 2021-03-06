#!/usr/bin/env bash

# Script based on the initial work of the Reddit user chrisawcom
# Contributions by: beeftornado, maxengel, stockmind

if [[ $(pgrep Xorg -c) == 1 ]]; then
	DISPLAY=:0
else
	DISPLAY=:1
fi

# determine necessary variables
XAUTHORITY=$(ps aux |grep -e Xorg | head -n1 | awk '{ split($0, a, "-auth "); split(a[2], b, " "); print b[1] }')
XAUTHORITY=$(echo "$XAUTHORITY" | sed "s|\(\:[0-9]\+\)|$DISPLAY|g")
export DISPLAY XAUTHORITY

# try at least 3 times to set correct transformation matrix
for k in `seq 1 3`;
do 

	#echo "trying $k..."
	SEARCH="Goodix Capacitive TouchScreen"

	id=$(xinput list --id-only pointer:"Goodix Capacitive TouchScreen")

    currentmatrix=$(echo -e $(xinput list-props $id | grep 'Coordinate Transformation Matrix' | cut -d ':' -f2))
	#echo "Current matrix: $currentmatrix"

	if [ "$currentmatrix" != "0.000000, 1.000000, 0.000000, -1.000000, 0.000000, 1.000000, 0.000000, 0.000000, 1.000000" ]; then
		# Rotate every instance of Touchscreen, this will workaround the ambiguity warning problem
		# that arise when calling xinput on "Goodix Capacitive Touchscreen"
		xinput set-prop $id "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1

		currentmatrix=$(echo -e $(xinput list-props $id | grep 'Coordinate Transformation Matrix' | cut -d ':' -f2))
		#echo "Done. Current matrix: $currentmatrix"
	fi

	currentorientation=$(echo -e $(xrandr -q | grep DSI1 | cut -b37-43))
	echo $currentorientation

	if [ "$currentorientation" != "right" ]; then
		# try also to rotate display if monitors file gets ignored
		xrandr --output DSI1 --rotate right
	fi

    currentaxesswap=$(echo -e $(xinput list-props $id | grep 'Evdev Axes Swap' | cut -d ':' -f2))

    # If the proprierty exists (It seems to be present on Official GPD Firmware Kernel)
    # Axes should be inverted to let touch work correctly
    if [ -n "$currentaxesswap" ]; then

		if [ "$currentaxesswap" != "0" ]; then
			xinput set-prop $id "Evdev Axes Swap" 0

			currentmatrix=$(echo -e $(xinput list-props $id | grep 'Evdev Axes Swap' | cut -d ':' -f2))
		fi

	    currentaxesinversion=$(echo -e $(xinput list-props $id | grep 'Evdev Axis Inversion' | cut -d ':' -f2))

		if [ "$currentaxesinversion" != "0, 0" ]; then
			xinput set-prop $id "Evdev Axis Inversion" 0 0

			currentmatrix=$(echo -e $(xinput list-props $id | grep 'Evdev Axis Inversion' | cut -d ':' -f2))
		fi

	fi

	sleep 3	
	# wait for X loading on every try
done  
