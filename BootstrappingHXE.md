# Bootstrapping a new HANA Express Container

## Prerequisites

1. You've pulled the HANA Express Docker Image per usual SAP Tutorials.
2. You've manually downloaded the required XSC Delivery Units.  See [here](DeliveryUnits.md) for details on why and how to do this.

## First-time Container Launch

This first launch basically:

  1. Spins up your Docker container passes the required master password
  2. Designates the volume name `hana-db` for further use in our Docker Compose stack.
  3. Passes a volume mapping for your downloaded delivery units mentioned in the pre-requisites so that we can install missing XS Classic content.
  
  For all the examples in this repository, I'll specify `SYSTEM` password as `HXEHana1` however change as you see fit if you wish.

- Linux/Mac:

   ```bash
   docker run --rm \
      --name hxe \
      --hostname hxe \
      -v hana-db:/hana/mounts \
      -v /path/to/your/xsc/deliveryunits:/usr/sap/HXE/SYS/global/hdb/content \
      store/saplabs/hanaexpress:2.00.045.00.20200121.1 \
      --agree-to-sap-license \
      --master-password HXEHana1
   ```

- Windows:

   ```cmd
   docker run --rm ^
       --name hxe ^
       --hostname hxe ^
       -v hana-db:/hana/mounts ^
       -v /c/Users/USERNAME/path/to/your/deliveryunits:/usr/sap/HXE/SYS/global/hdb/content ^
       store/saplabs/hanaexpress:2.00.045.00.20200121.1 ^
       --agree-to-sap-license ^
       --master-password HXEHana1
   ```

Once the container says `Startup finished`, proceed with the next section to install XSC Delivery Units.

## Install XSC and SDI Delivery Units

In a separate terminal window with your container still running, follow these steps.

1. Run the following command to install pre-requisites:

   `docker exec -ti hxe /bin/bash -c "cd /hana/shared/HXE/global/hdb/content;/usr/sap/HXE/HDB90/exe/regi import HANA_DT_BASE.tgz  HANA_XS_BASE.tgz SAP_WATT.tgz HDC_IDE_CORE.tgz HANA_XS_EDITOR.tgz HANA_IDE_CORE.tgz HANA_XS_IDE.tgz SAPUI5_1.tgz HANA_IM_DP-2.4.2-hf1 --host=hxe:39041 --user=SYSTEM --password=HXEHana1"`

Once the delivery units have installed with an `Import successful` message, proceed to the next step.

## Re-launch HANA Express in Docker Compose

In a terminal window, stop your HANA Express Container's initial launch by typing `docker stop hxe`.  Once the container has stopped, we can now launch our entire Docker Compose Stack (`docker-compose.yaml`.)

We need to make a few remaining changes to our DB to make it accessible via HANA Studio, and over XS Engine (http), as well as enable Data Provisioning Server and registering a Data Provisioning Agent.

1. Type `docker-compose up` and wait a few minutes for all the docker containers to start up.

2. Once the stack has finished starting, type `docker exec -ti hxe /bin/bash` to enter your HANA Express Container OS.

## Configure access to HANA Express from HANA Studio and add DP Server to `HXE` Tenant DB.

These steps will enable your HANA DB to be reachable via HANA Studio.  This more convenient than modifying `/etc/hosts` file in Linux/Mac or Windows.  Also since we'll be connected to the SYSTEMDB, we'll go ahead and add the `dpserver` we'll need later.

***Note:** Replace `192.168.99.100` with whatever hostname you use for your Docker daemon (such as `localhost` or your AWS EC2/ECS host/IP, etc.)*

1. Once in your HANA Express OS, type `hdbsql -n hxe:39017 -u SYSTEM -p HXEHana1` to enter hdbsql connected to your `SYSTEMDB`.

2. Run the following commands:

   ```sql
   ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'system') SET ('public_hostname_resolution', 'use_default_route') = 'name' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'system') SET ('public_hostname_resolution', 'map_hxe') = '192.168.99.100' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'http_url') = 'http://192.168.99.100:8090' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'https_url') = 'http://192.168.99.100:4390' WITH RECONFIGURE;
   ALTER DATABASE HXE ADD 'dpserver';
   ```

3. Type `exit` to exit hdbql.

After about 1-2 minutes, you should be able to connect to your HANA Express container via your Docker Daemon host name/IP in HANA Studio, but we have some more changes to make instead of waiting.

## Make XS Classic Engine use `HXE` Tenant DB

These steps will adjust your XS Engine to listen on your Docker Daemon's host/IP address and use the `HXE` Tenant DB.

***Note:** Replace `192.168.99.100` with whatever hostname you use for your Docker daemon (such as `localhost` or your AWS EC2/ECS host/IP, etc.)*

1. Once in your HANA Express OS, type `hdbsql -n hxe:39041 -u SYSTEM -p HXEHana1` to enter hdbsql connected to your `HXE` Tenant.

2. Run the following commands:

   ```sql
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'database') SET ('public_urls', 'http_url') = 'http://192.168.99.100:8090' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'database') SET ('public_urls', 'http_url') = 'https://192.168.99.100:4390' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'http_url') = 'http://192.168.99.100:8090' WITH RECONFIGURE;
   ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'https_url') = 'http://192.168.99.100:4390' WITH RECONFIGURE;
   ```

Stay in hdbsql and proceed to the next section.

## Register your DP Agent Container in your `HXE` tenant DB

Register your dpagent container named `dpagent` with `HXE` Tenant DB, and register 2 DB Adapters with the following commands:

   ```sql
   CREATE AGENT dpagent PROTOCOL 'TCP' host 'dpagent' PORT 5050;
   CREATE ADAPTER "OracleLogReaderAdapter" AT LOCATION AGENT dpagent;
   CREATE ADAPTER "MssqlLogReaderAdapter" AT LOCATION AGENT dpagent;
   ```

Stay in hdbsql and proceed to the next section.

## Grant `SYSTEM` user some XS Classic roles

Since this is just a play box, let's keep using `SYSTEM` user and add the roles needed to use the old Web-based Development Workbench and Data Provisioning Monitor.

Run the following commands:

   ```sql
   CALL GRANT_ACTIVATED_ROLE ('sap.hana.xs.ide.roles::CatalogDeveloper','SYSTEM');
   CALL GRANT_ACTIVATED_ROLE ('sap.hana.xs.ide.roles::Developer','SYSTEM');
   CALL GRANT_ACTIVATED_ROLE ('sap.hana.im.dp.monitor.roles::Monitoring','SYSTEM');
   CALL GRANT_ACTIVATED_ROLE ('sap.hana.im.dp.monitor.roles::Operations','SYSTEM');
   ```
