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
    STATUS=0
    FR=12
    IE=3
    PAUSE=150
    VC=$(((RANDOM % 50) + 425))
    FIO2=50
    PEEP=$(( RANDOM % 25 ))
    echo Reportando para el respirador $((VENTILATOR)): { status: $((STATUS)), fr: $((FR)), ie: $((IE)), pause: $((PAUSE)), vc: $((VC)), fio2: $((FIO2)), peep: $((PEEP)) }
    curl -H "Content-Type: application/json" -X POST --silent --show-error http://$VENTILATORS_MOCK_RECEIVER_HOST:$VENTILATORS_MOCK_RECEIVER_PORT/ventilators/$VENTILATOR/measurements -d "{ \"status\": $((STATUS)), \"fr\": $((FR)), \"ie\": $((IE)), \"pause\": $((PAUSE)), \"vc\": $((VC)), \"fio2\": $((FIO2)), \"peep\": $((PEEP)) }"
  done
  sleep 5
done
