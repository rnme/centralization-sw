#!/bin/bash

echo Intentanto establecer el password del usuario administrador...
curl -X PUT -H 'Content-Type: application/json' --user ${DASHBOARD_INITIALIZER_ADMIN_USER}:admin -i ${DASHBOARD_INITIALIZER_API_URL}/api/admin/users/1/password --data "{
  \"password\":\"$DASHBOARD_INITIALIZER_ADMIN_PASSWORD\"
}" > /dev/null 2>/dev/null
if [ $? -eq 0 ]; then
  echo Se estableció el password del usuario administrador.
else
  echo No se pudo establecer el password del usuario administrador.
  exit 1
fi
echo Intentando establecer el tablero principal...
curl -X PUT -H 'Content-Type: application/json' --user ${DASHBOARD_INITIALIZER_ADMIN_USER}:${DASHBOARD_INITIALIZER_ADMIN_PASSWORD} -i ${DASHBOARD_INITIALIZER_API_URL}/api/org/preferences --data "{
  \"theme\":\"\",
  \"homeDashboardId\":${DASHBOARD_INITIALIZER_HOME_DASHBOARD_ID},
  \"timezone\":\"\"
}" > /dev/null 2>/dev/null
if [ $? -eq 0 ]; then
  echo Se estableció el tablero principal.
  exit 0
else
  echo No se pudo establecer el tablero principal.
  exit 1
fi
