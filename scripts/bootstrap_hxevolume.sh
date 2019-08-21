#!/bin/bash

docker run --rm \
    --name hxe \
    --hostname hxe \
    -v $1:/hana/mounts \
    store/saplabs/hanaexpress:2.00.040.00.20190729.1 \
    --agree-to-sap-license \
    --master-password $2