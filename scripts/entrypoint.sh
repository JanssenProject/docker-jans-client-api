#!/bin/sh

set -e

python3 /app/scripts/wait.py

if [ ! -f /deploy/touched ]; then
    python3 /app/scripts/entrypoint.py
    touch /deploy/touched
fi

# run the server
# customized `/opt/client-api/bin/client-api-start.sh`
exec java \
    -Djava.net.preferIPv4Stack=true \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=$CLOUD_NATIVE_MAX_RAM_PERCENTAGE \
    ${CLOUD_NATIVE_JAVA_OPTIONS} \
    -cp /opt/client-api/client-api.jar:/opt/client-api/lib/* \
    org.gluu.client-api.server.client-apiServerApplication server /opt/client-api/conf/client-api.yml
