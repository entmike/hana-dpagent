docker run --rm ^
    --name hxe ^
    --hostname hxe ^
    -v %1:/hana/mounts ^
    -p 39017:39017 ^
    -p 39041:39041 ^
    -p 39013:39013 ^
    -p 39015:39015 ^
    -p 8090:8090 ^
    store/saplabs/hanaexpress:2.00.040.00.20190729.1 ^
    --agree-to-sap-license ^
    --master-password %2