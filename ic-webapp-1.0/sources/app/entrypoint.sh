#!/bin/sh
Release_file=/opt/releases.txt

if test -f "$Release_file"; then
  echo "---- Setting ODOO_URL and PGADMIN_URL ----"
  export ODOO_URL=$( awk 'NR==1 {print $2}' $Release_file )
  export PGADMIN_URL=$( awk 'NR==2 {print $2}' $Release_file )
else
  echo "You did not send ODOO_URL and PGADMIN_URL, we are going to use default URL setted on Dockerfile"
fi

exec "$@"