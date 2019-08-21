# Bootstrapping a new HANA Express Container

## Run the launch script

### Windows

`bootstrap_hxevolume.cmd hana-db HXEHana1`

### Linux

`./bootstrap_hxevolume.sh hana-db HXEHana1`

Once the script ends with `Startup finished`, in a second Terminal, run the following commands:

1. These 2 commands will enable your HANA DB to be reachable via HANA Studio:

   `docker exec -ti hxe /bin/bash -c ". ~/.profile; hdbsql -n hxe:39017 -u SYSTEM -p HXEHana1 \"ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'system') SET ('public_hostname_resolution', 'use_default_route') = 'name' WITH RECONFIGURE;\""`

   `docker exec -ti hxe /bin/bash -c ". ~/.profile; hdbsql -n hxe:39017 -u SYSTEM -p HXEHana1 \"ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'system') SET ('public_hostname_resolution', 'map_hxe') = '192.168.99.100' WITH RECONFIGURE;\""`
