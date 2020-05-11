#!/bin/bash
EXCLUDED=()

show_help() {
  echo "Simulación de reporte de mediciones de respiradores."
  echo "Uso: $0 [OPCIONES]"
  echo "Opciones:"
  echo -e "\t--count\tCantidad de respiradores. (Obligatorio)"
  echo -e "\t--exclude\t\tID de un respirador que se quiere excluir. Puede indicarse varias veces."
  echo -e "\t--help\t\t\tEl script muestra este mensaje y no hace más nada."
  exit
}

if [ $# -eq 0 ]; then
  show_help
fi

while true; do
  case "$1" in
    --count ) VENTILATOR_COUNT=$2; shift 2 ;;
    --exclude ) EXCLUDED+=($2); shift 2 ;;
    --help ) show_help ;;
    * ) break ;;
  esac
done
echo Simulando $VENTILATOR_COUNT respiradores
while :
do
  for VENTILATOR in $(seq 1 $VENTILATOR_COUNT)
  do
    if [[ " ${EXCLUDED[@]} " =~ " $VENTILATOR " ]];
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
