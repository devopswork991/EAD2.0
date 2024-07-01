#!/bin/bash
# Generate certificates for your OpenSearch cluster

OPENDISTRO_DN="/C=FR/ST=IDF/L=PARIS/O=EXAMPLE"   # Edit here and in opensearch.yml

mkdir -p certs/{ca,keycloak,os-dashboards}

# Root CA
openssl genrsa -out certs/ca/ca.key 2048
openssl req -new -x509 -sha256 -days 1095 -subj "$OPENDISTRO_DN/CN=CA" -key certs/ca/ca.key -out certs/ca/ca.pem

# Admin
openssl genrsa -out certs/ca/admin-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/ca/admin-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/ca/admin.key
openssl req -new -subj "$OPENDISTRO_DN/CN=ADMIN" -key certs/ca/admin.key -out certs/ca/admin.csr
openssl x509 -req -in certs/ca/admin.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/ca/admin.pem

# OpenSearch Dashboards
openssl genrsa -out certs/os-dashboards/os-dashboards-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/os-dashboards/os-dashboards-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/os-dashboards/os-dashboards.key
openssl req -new -subj "$OPENDISTRO_DN/CN=os-dashboards" -key certs/os-dashboards/os-dashboards.key -out certs/os-dashboards/os-dashboards.csr
openssl x509 -req -in certs/os-dashboards/os-dashboards.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/os-dashboards/os-dashboards.pem
rm certs/os-dashboards/os-dashboards-temp.key certs/os-dashboards/os-dashboards.csr

# Nodes
for NODE_NAME in "os01" "os02" "os03"
do
    mkdir "certs/${NODE_NAME}"
    openssl genrsa -out "certs/$NODE_NAME/$NODE_NAME-temp.key" 2048
    openssl pkcs8 -inform PEM -outform PEM -in "certs/$NODE_NAME/$NODE_NAME-temp.key" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "certs/$NODE_NAME/$NODE_NAME.key"
    openssl req -new -subj "$OPENDISTRO_DN/CN=$NODE_NAME" -key "certs/$NODE_NAME/$NODE_NAME.key" -out "certs/$NODE_NAME/$NODE_NAME.csr"
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1,DNS:$NODE_NAME") -in "certs/$NODE_NAME/$NODE_NAME.csr" -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out "certs/$NODE_NAME/$NODE_NAME.pem"
    rm "certs/$NODE_NAME/$NODE_NAME-temp.key" "certs/$NODE_NAME/$NODE_NAME.csr"
done

# Generate Keycloak certificate, signed by your CA
openssl genrsa -out certs/keycloak/keycloak-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/keycloak/keycloak-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/keycloak/keycloak.key
openssl req -new -subj "$OPENDISTRO_DN/CN=keycloak" -key certs/keycloak/keycloak.key -out certs/keycloak/keycloak.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1,DNS:keycloak-ead.rdtex.msk.ru") -in certs/keycloak/keycloak.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/keycloak/keycloak.pem

# Configuring filenames and rights for Keycloak container
cp certs/keycloak/keycloak.key certs/keycloak/tls.key
cp certs/keycloak/keycloak.pem certs/keycloak/tls.crt
chmod 655 certs/keycloak/tls.crt certs/keycloak/tls.key

# Cleanup
rm certs/ca/admin-temp.key certs/ca/admin.csr
rm certs/os-dashboards/os-dashboards-temp.key certs/os-dashboards/os-dashboards.csr
rm certs/keycloak/keycloak-temp.key certs/keycloak/keycloak.csr

# Adjusting permissions
chmod 700 certs/{ca,os-dashboards}
chmod 600 certs/{ca/*,os-dashboards/*}

#chmod -R 750 ./certs
#chown -R $USER:1000 ./certs