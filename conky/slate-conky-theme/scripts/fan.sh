#! /bin/bash

fan=`sensors | grep -i fan1 | awk '{print $2 " " $3}'`
echo $fan