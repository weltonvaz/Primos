#!/bin/bash
clear

N=1009

for P in `seq 2 $N`
do 
      [ "`echo "$N % $P"|bc`" == "0" ] || continue
      Q="`echo $N / $P|bc`"
      echo P=$P Q=$Q
      break
done
