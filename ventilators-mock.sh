#!/bin/bash
EXCLUDED=$1
while :
do
  for VENTILATOR in {1..50}
  do
    if [ $((VENTILATOR)) -eq $((EXCLUDED)) ]
    then
      echo Salteando respirador $VENTILATOR
      continue
    fi
    VENTILATOR_ID=$(printf "%02d" $((VENTILATOR)))
    STATUS=0
    FR=12
    IE=3
    PAUSE=150
    VC=$(((RANDOM % 50) + 425))
    FIO2=50
    PEEP=$(( RANDOM % 25 ))
    echo Reportando 'ventilator_measurement': { ventilator: ${VENTILATOR_ID}, status: $((STATUS)), fr: $((FR)), ie: $((IE)), pause: $((PAUSE)), vc: $((VC)), fio2: $((FIO2)), peep: $((PEEP)) }
    influx -database 'ventilators' -execute "insert ventilator_measurement,ventilator=${VENTILATOR_ID} status=$((STATUS))i,fr=$((FR))i,ie=$((IE))i,pause=$((PAUSE))i,vc=$((VC))i,fio2=$((FIO2))i,peep=$((PEEP))i"
  done
  sleep 5
done
