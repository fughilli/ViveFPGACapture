#!/bin/bash

function program()
{
    mojo-loader -i build/design.bit -r -p -d /dev/serial/by-id/usb-Embedded_Micro_Mojo_V3-if00
}

for arg in $@
do

    if [[ $arg == "-p" ]]
    then
        program
    fi

done
