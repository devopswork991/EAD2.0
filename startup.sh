#!/bin/bash

####Environment MINIO
#### export MINIO_ROOT_USER=minioadmin
#### export MINIO_ROOT_PASSWORD=Admin1234_5
#### export MINIO_URL=

####Environment OPENSEARCH
#### export OPENSEARCH_USERNAME=admin
#### export OPENSEARCH_PASSWORD=admin
#### export OPENSEARCH_DAHBOARD_URL=

#### Set alias
#### mc alias set minio_new http://localhost:9000 minioadmin Admin1234_5

#### Start Docker Compose Project
docker-compose up -d
sleep 50

#### Wait about 50 seconds and run securityadmin to initialize the security plugin :
docker-compose exec os01 bash -c "chmod +x plugins/opensearch-security/tools/securityadmin.sh && bash plugins/opensearch-security/tools/securityadmin.sh -cd config/opensearch-security -icl -nhnv -cacert config/certificates/ca/ca.pem -cert config/certificates/ca/admin.pem -key config/certificates/ca/admin.key -h localhost"

#### Access MinIO Dashboards through http://localhost:9002
#### Access OpenSearch Dashboards through https://localhost:5601
