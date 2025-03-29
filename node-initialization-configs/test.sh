#!/bin/bash
for i in $(seq 1 10); do
    echo $i
done

i=0
for [ "$i" -lt 10 ]; do
    echo $i
    i=$i+1
done
