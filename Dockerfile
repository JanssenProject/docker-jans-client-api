FROM adoptopenjdk/openjdk11:jre-11.0.8_10-alpine

# symlink JVM
RUN mkdir -p /usr/lib/jvm/default-jvm /usr/java/latest \
    && ln -sf /opt/java/openjdk /usr/lib/jvm/default-jvm/jre \
    && ln -sf /usr/lib/jvm/default-jvm/jre /usr/java/latest/jre

# ===============
# Alpine packages
# ===============

RUN apk update \
    && apk add --no-cache openssl py3-pip tini curl \
    && apk add --no-cache --virtual build-deps unzip wget git

# ==========
# Client API
# ==========

ENV CLOUD_NATIVE_VERSION=5.0.0-SNAPSHOT
ENV CLOUD_NATIVE_BUILD_DATE="2020-09-24 08:33"

RUN wget -q https://ox.gluu.org/maven/org/gluu/client-api/${CLOUD_NATIVE_VERSION}/client-api-${CLOUD_NATIVE_VERSION}-distribution.zip -O /client-api.zip \
    && mkdir -p /opt/client-api \
    && unzip -qq /client-api.zip -d /opt/client-api \
    && rm /client-api.zip \
    && rm -rf /opt/client-api/conf/client-api.keystore /opt/client-api/conf/client-api.yml

EXPOSE 8443 8444

# ======
# Python
# ======

RUN apk add --no-cache py3-cryptography
COPY requirements.txt /app/requirements.txt
RUN pip3 install -U pip \
    && pip3 install --no-cache-dir -r /app/requirements.txt \
    && rm -rf /src/pygluu-containerlib/.git

# =======
# Cleanup
# =======

RUN apk del build-deps \
    && rm -rf /var/cache/apk/*

# =======
# License
# =======

RUN mkdir -p /licenses
COPY LICENSE /licenses/

# ==========
# Config ENV
# ==========

ENV CLOUD_NATIVE_CONFIG_ADAPTER=consul \
    CLOUD_NATIVE_CONFIG_CONSUL_HOST=localhost \
    CLOUD_NATIVE_CONFIG_CONSUL_PORT=8500 \
    CLOUD_NATIVE_CONFIG_CONSUL_CONSISTENCY=stale \
    CLOUD_NATIVE_CONFIG_CONSUL_SCHEME=http \
    CLOUD_NATIVE_CONFIG_CONSUL_VERIFY=false \
    CLOUD_NATIVE_CONFIG_CONSUL_CACERT_FILE=/etc/certs/consul_ca.crt \
    CLOUD_NATIVE_CONFIG_CONSUL_CERT_FILE=/etc/certs/consul_client.crt \
    CLOUD_NATIVE_CONFIG_CONSUL_KEY_FILE=/etc/certs/consul_client.key \
    CLOUD_NATIVE_CONFIG_CONSUL_TOKEN_FILE=/etc/certs/consul_token \
    CLOUD_NATIVE_CONFIG_KUBERNETES_NAMESPACE=default \
    CLOUD_NATIVE_CONFIG_KUBERNETES_CONFIGMAP=gluu \
    CLOUD_NATIVE_CONFIG_KUBERNETES_USE_KUBE_CONFIG=false

# ==========
# Secret ENV
# ==========

ENV CLOUD_NATIVE_SECRET_ADAPTER=vault \
    CLOUD_NATIVE_SECRET_VAULT_SCHEME=http \
    CLOUD_NATIVE_SECRET_VAULT_HOST=localhost \
    CLOUD_NATIVE_SECRET_VAULT_PORT=8200 \
    CLOUD_NATIVE_SECRET_VAULT_VERIFY=false \
    CLOUD_NATIVE_SECRET_VAULT_ROLE_ID_FILE=/etc/certs/vault_role_id \
    CLOUD_NATIVE_SECRET_VAULT_SECRET_ID_FILE=/etc/certs/vault_secret_id \
    CLOUD_NATIVE_SECRET_VAULT_CERT_FILE=/etc/certs/vault_client.crt \
    CLOUD_NATIVE_SECRET_VAULT_KEY_FILE=/etc/certs/vault_client.key \
    CLOUD_NATIVE_SECRET_VAULT_CACERT_FILE=/etc/certs/vault_ca.crt \
    CLOUD_NATIVE_SECRET_KUBERNETES_NAMESPACE=default \
    CLOUD_NATIVE_SECRET_KUBERNETES_SECRET=gluu \
    CLOUD_NATIVE_SECRET_KUBERNETES_USE_KUBE_CONFIG=false

# ===============
# Persistence ENV
# ===============

ENV CLOUD_NATIVE_PERSISTENCE_TYPE=ldap \
    CLOUD_NATIVE_PERSISTENCE_LDAP_MAPPING=default \
    CLOUD_NATIVE_LDAP_URL=localhost:1636 \
    CLOUD_NATIVE_COUCHBASE_URL=localhost \
    CLOUD_NATIVE_COUCHBASE_USER=admin \
    CLOUD_NATIVE_COUCHBASE_CERT_FILE=/etc/certs/couchbase.crt \
    CLOUD_NATIVE_COUCHBASE_PASSWORD_FILE=/etc/gluu/conf/couchbase_password \
    CLOUD_NATIVE_COUCHBASE_CONN_TIMEOUT=10000 \
    CLOUD_NATIVE_COUCHBASE_CONN_MAX_WAIT=20000 \
    CLOUD_NATIVE_COUCHBASE_SCAN_CONSISTENCY=not_bounded

# =======
# client-api ENV
# =======

ENV CLOUD_NATIVE_CLIENT_API_APPLICATION_CERT_CN="localhost" \
    CLOUD_NATIVE_CLIENT_API_ADMIN_CERT_CN="localhost" \
    CLOUD_NATIVE_CLIENT_API_BIND_IP_ADDRESSES="*"

# ===========
# Generic ENV
# ===========

ENV CLOUD_NATIVE_MAX_RAM_PERCENTAGE=75.0 \
    CLOUD_NATIVE_WAIT_MAX_TIME=300 \
    CLOUD_NATIVE_WAIT_SLEEP_DURATION=10 \
    CLOUD_NATIVE_JAVA_OPTIONS="" \
    CLOUD_NATIVE_SSL_CERT_FROM_SECRETS=false

# ====
# misc
# ====

LABEL name="Client API" \
    maintainer="Gluu Inc. <support@gluu.org>" \
    vendor="Janssen" \
    version="5.0.0" \
    release="dev" \
    summary="Gluu client API" \
    description="Client software to secure apps with OAuth 2.0, OpenID Connect, and UMA"

RUN mkdir -p /etc/certs /app/templates/ /deploy /etc/gluu/conf
COPY scripts /app/scripts
COPY templates/*.tmpl /app/templates/
RUN chmod +x /app/scripts/entrypoint.sh

ENTRYPOINT ["tini", "-e", "143", "-g", "--"]
CMD ["sh", "/app/scripts/entrypoint.sh"]
