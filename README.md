# HANA Data Provisioning Agent Docker Image

Builds a Docker Image with Data Provisioning Agent pre-installed with some common JAR files included.  Since `HXEDownloadManager_linux.bin` is used to actually download the software, it will pull whatever the latest is available from SAP (for instance, 2.0 SP3 or SP4 etc)  So tag your builds with something appropriate if needed.

## Purpose

If you are playing with SAP HANA Express Docker container and want to quickly spin up a Data Provisioning Agent without bothering with a VM and copying JARs and installing DP Agent, the following build will result in a Data Provisioning Agent which you can then use with HANA Express.

## Prerequisites

- Download and place the following files in the files directory.  I technically cannot redistribute them in the repo, and they are large binaries anyway.

  - In `/files` copy `HXEDownloadManager_linux.bin` - Follow the [tutorial here](https://developers.sap.com/tutorials/hxe-ua-register.html) or Google for it.
  - In `/files/sdi-libs` copy your database JDBC JARs.  (Google them or find on Microsoft/Oracle/etc sites) i.e:

    - `sqljdbc4.jar` Microsoft SQL Server JAR
    - `ojdbc7.jar` Oracle DB JAR

## Building

   1. `git clone https://github.com/entmike/hana-dpagent.git`
   2. Copy the files mentioned in the prerequisites to the correct folders.
   3. `cd hana-dpagent`
   4. `docker build -t dpagent-image .`

## Bare Bones example of just running Data Provisioning Image

The following is a very bare-bones simple example of how to run the Data Provisioning Agent in a single docker container.  In this example, the container is removed after it is stopped and no data, configuration files, or logs are persisted.

### Start a container in Docker

`docker run -d -p 5050:5050 --rm --name dpagent dpagent-image`

### Accessing the Data Provisioning Agent CLI configuration menu

`docker exec -ti dpagent bash -c "/home/dpagent/dataprovagent/bin/agentcli.sh --configAgent"`

## Simple Running Example in Docker Compose

Realistically in a containerized scenario, you'll simply just want to have DP Agent and HXE running in same Docker network.  Docker Compose makes this simple and easy for the 2 containers to communicate internally.

Note: This example assumes:

  1. You built your Docker Image called `dpagent-image`

  2. You have a bootstrapped HANA Express container.

```yaml
version: '2'

services:

  dpagent:
    image: dpagent-image
    container_name: dpagent
    hostname: dpagent

  hxe:
    image: store/saplabs/hanaexpress:2.00.045.00.20200121.1
    container_name: hxe
    hostname: hxe
    volumes:
      - hana-db:/hana/mounts

volumes:
  hana-db:
    external:
      name: hana-db
```

### Configuring Data Provisioning Agent and Adapter(s) from CLI in this Docker Compose Stack

To configure the DP Agent via the CLI Tool, read [instructions here](DPAgentConfig.md).

## Running Example in Docker Compose with Oracle DB

This next example illustrates a similar Docker Compose stack with the addition of an Oracle 12 Database that can be used by the DP Agent and HANA Express Containers for an end-to-end sandbox to play with Data Provisioning Agent and SDA.  (After all, this example Docker Compose stack is not a complete self-contained working example if it did not contain an example Data Source, right?)

**Note:** This example assumes:

  1. You built your Docker Image called `dpagent-image`
  2. You are running an existing HANA Express (2.0 SP4 in this case) with a hostname of `hxe` and a pre-existing docker volume named `hana-db`.
  
     *(Simply run `docker volume create hana-db` if you have not)*

  3. You have a pre-existing docker volume named `oracle-db`.

     *(Simply run `docker volume create oracle-db` if you have not)*

  4. You have a Docker Hub login and have subscribed to the [Oracle DB image](https://hub.docker.com/_/oracle-database-enterprise-edition)

```yaml
version: '2'

services:

  dpagent:
    image: dpagent-image
    container_name: dpagent
    hostname: dpagent

  hxe:
    image: store/saplabs/hanaexpress:2.00.045.00.20200121.1
    container_name: hxe
    hostname: hxe
    volumes:
      - hana-db:/hana/mounts

    ports:
      - 39041:39041
      - 39017:39017
      - 39013:39013
      - 39015:39015
      - 8090:8090

  oracle:
    image: store/oracle/database-enterprise:12.2.0.1-slim
    container_name: oracle
    hostname: oracle
    ports:
      - 1521:1521
    volumes:
      - oracle-db:/ORCL

volumes:
  hana-db:
    external:
      name: hana-db

  oracle-db:
    external:
      name: oracle-db

```

## Connecting to your Oracle Container's DB

The Oracle Docker image comes with a container database (`ORCLCDB`) and a pluggable database (`ORCLPDB1`.)  Data Provisioning Agent can communicate with either, however if you wish to use realtime replication, you must connect to the container database (`ORCLCDB`), as Oracle's LogMiner does not work with pluggable databases.  Therefore, for sake of this use case, we will cover primarily the container database.

### Option 1: Connecting to Oracle DB Container's `ORCLCDB` (pluggable DB) in sqlplus as sysdba

- sqlplus method

   ```bash
   docker exec -ti oracle /bin/bash
   sqlplus sys/Oradoc_db1@ORCLCDB as sysdba
   ```

- sqldeveloper method
   | Property | Value |
   | --- | --- |
   | Connection Name | Whatever you want |
   | Username | `sys` (Case-sensitive) |
   | Password | `Oradoc_db1` |
   | Role | `SYSDBA` |
   | Hostname | `192.168.99.100` or `localhost` or wherever your container runs |
   | Service name | `ORCLCDB.localdomain` |

### Option 2: Connecting to Oracle DB Container's `ORCLPDB1` (pluggable DB) in sqlplus as sysdba

This is simply for reference as we will not be using this pluggable DB in any examples.

- sqlplus method

   ```bash
   docker exec -ti oracle /bin/bash
   sqlplus sys/Oradoc_db1@ORCLPDB1 as sysdba
   ```

- sqldeveloper method
   | Property | Value |
   | --- | --- |
   | Connection Name | Whatever you want |
   | Username | `sys` (Case-sensitive) |
   | Password | `Oradoc_db1` |
   | Role | `SYSDBA` |
   | Hostname | `192.168.99.100` or `localhost` or wherever your container runs |
   | Service name | `ORCLPDB1.localdomain` |

### Configure DB for Realtime Replication

Before we can use realtime replication, we need to enable archive logs on the Container DB.  The following commands **must** be run from `sqlplus` as `sys` on `ORCLCDB`.

```bash
docker exec -ti oracle /bin/bash
mkdir /ORCL/archivelogs
sqlplus sys/Oradoc_db1@ORCLCDB as sysdba
SQL*Plus: Release 12.2.0.1.0 Production on Wed Aug 21 13:46:53 2019

Copyright (c) 1982, 2016, Oracle.  All rights reserved.

Last Successful login time: Wed Aug 21 2019 13:45:53 +00:00

Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```

Type `SHUTDOWN IMMEDIATE;`

```bash
SQL> SHUTDOWN IMMEDIATE;
Database closed.
Database dismounted.
ORACLE instance shut down.
ERROR:
ORA-12514: TNS:listener does not currently know of service requested in connect
descriptor


Warning: You are no longer connected to ORACLE.
```

Type `CONNECT SYS/Oradoc_db1 AS SYSDBA;`

```bash
SQL> CONNECT sys/Oradoc_db1 AS SYSDBA;
Connected to an idle instance.
```

Type `STARTUP MOUNT;`

```bash
SQL> STARTUP MOUNT;
ORACLE instance started.
                            8792536 bytes
Variable SizeGlobal Area  352323112 bytes
Database Buffers            7983104 bytes
Database mounted.
```

Type `ALTER DATABASE ARCHIVELOG;`

```bash
SQL> ALTER DATABASE ARCHIVELOG;

Database altered.
```

Type `ALTER DATABASE OPEN;`

```bash
SQL> ALTER DATABASE OPEN;

Database altered.
```

Execute the following to specify a local directory as the archive log directory (a.k.a archive destination.)

`ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/ORCL/archivelogs';`

```bash
SQL> ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/ORCL/archivelogs';

System altered.
```

Enable minimal database-level supplemental logging

`ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;`

```bash
SQL> ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

Database altered.
```

We will be setting Oracle LogReader Adapter preference for Oracle supplemental logging level to `database` so we need to enable PRIMARY KEY and UNIQUE KEY database-level supplemental logging:

Type `ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY, UNIQUE) COLUMNS;`

```bash
SQL> ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY, UNIQUE) COLUMNS;

Database altered.
```

Type `ALTER SYSTEM SET db_securefile='PERMITTED';`

```bash
SQL> ALTER SYSTEM SET db_securefile='PERMITTED';

System altered.
```

Type `exit` to exit `sqlplus`.

```bash
SQL> exit
Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```

### Set up Oracle Replication the Easy Way

For the hard way, see here.

1. Connect to your Data Provisioning Agent Container and run the Replication Setup tool.

   `docker exec -ti dpagent bash -c "/home/dpagent/dataprovagent/bin/agentcli.sh --replicationSetup`

   ```bash
   ************************************************************
               Remote Source Replication Setup Tool
   ************************************************************
   1. Oracle Replication Setup
   2. Microsoft SQL Server Replication Setup
   3. DB2 Replication Setup
   q. Quit
   b. Back
   ************************************************************
   Enter Option:
   ************************************************************
   ```

2. Select option 1 (`Oracle Replication Setup`.)

   ```bash
   ************************************************************
                     Oracle Replication Setup
   ************************************************************
   1. Config Oracle Connection Info
   2. Oracle Replication Precheck
   3. List Open Transactions
   4. Create An Oracle User With All Permissions Granted
   5. Create Oracle Log Reader Adapter Remote Source
   q. Quit
   b. Back
   ************************************************************
   Enter Option:
   ************************************************************

3. Select option 1 (`Config Oracle Connection Info`).  Provide the following parameters:

   |Parameter|Value|
   |---|---|
   |Use SSL|`false`|
   |Multitenant Database|`false`|
   |Use LDAP Authentication|`false`|
   |Host|`oracle`|
   |Port Number|`1521`|
   |Database Name|`ORCLCDB`|
   |Service Name|`ORCLCDB.localdomain`|
   |User Name|`SYS`|`Oradoc_db1`|

   You should receive a confirmation message:

   ```bash
   ************************************************************
   Oracle connection setup -- success!
   ************************************************************
   Operation execution -- success!
   ************************************************************
   ```

4. And finally, we will use this tool to create the Oracle LogReader user and grant a lot of the required permissions needed for replication.  Select option 4 (`Create An Oracle user With All Permissions Granted`.)  Provide the following parameters:

   |Parameter|Values|
   |---|---|
   |New Oracle Username (Case Sensitive)|`C##LR_USER`|
   |New Oracle User's Password (Case Sensitive)|`HXEHana1`|
   |SYS User Password|`Oradoc_db1`|

   You should receive a confirmation message:

   ```txt
   ************************************************************
   Creating User Name: C##LR_USER
   Creating User Password: HXEHana1
   ************************************************************
   ************************************************************
   Oracle user creation -- success!
   ************************************************************
   Operation execution -- success!
   ************************************************************
   ```

5. At this point, we are done with the Replication Setup tool.  If you have deviated from this example, you may wish to run option 5 (`Create Oracle Log Reader Adapter Remote Source`) yourself.  If you run through that option, note that the Remote Source script that the tool creates will be located in the `/tmp` directory in the filesystem of the Data Provisioning Agent container.

6. In the `HXE` HANA Tenant DB as `SYSTEM`, run the following SQL in HANA Studio or `hdbsql`:

   ***NOTE:*** If you decided to call your data provisioining agent name something besides `dpagent_dpagent` or your password or user something else, modify those pieces in the XML below.

```sql
CREATE REMOTE SOURCE "oracle" ADAPTER "OracleLogReaderAdapter" AT LOCATION AGENT "dpagent_dpagent" CONFIGURATION
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ConnectionProperties name="configurations">
<PropertyEntry name="pds_database_name">ORCLCDB</PropertyEntry>
<PropertyEntry name="cdb_enabled">false</PropertyEntry>
<PropertyEntry name="keep_supplemental_logging_on_table">false</PropertyEntry>
<PropertyEntry name="pdb_supplemental_logging_level">database</PropertyEntry>
<PropertyEntry name="lr_max_op_queue_size">1000</PropertyEntry>
<PropertyEntry name="lr_deferred_rescan_enabled">false</PropertyEntry>
<PropertyEntry name="remarksReporting">false</PropertyEntry>
<PropertyEntry name="pds_port_number">1521</PropertyEntry>
<PropertyEntry name="lr_max_session_cache_size">1000</PropertyEntry>
<PropertyEntry name="pds_use_ldap">false</PropertyEntry>
<PropertyEntry name="skip_lr_errors">false</PropertyEntry>
<PropertyEntry name="pds_host_name">oracle</PropertyEntry>
<PropertyEntry name="pdb_dflt_column_repl">true</PropertyEntry>
<PropertyEntry name="pdb_ignore_unsupported_anydata">false</PropertyEntry>
<PropertyEntry name="pds_retry_count">5</PropertyEntry>
<PropertyEntry name="map_char_types_to_unicode">false</PropertyEntry>
<PropertyEntry name="service_name">ORCLCDB.localdomain</PropertyEntry>
<PropertyEntry name="pds_retry_timeout">10</PropertyEntry>
<PropertyEntry name="lr_max_scan_queue_size">1000</PropertyEntry>
<PropertyEntry name="instance_name">dpagent</PropertyEntry>
<PropertyEntry name="pds_use_ssl">false</PropertyEntry>
<PropertyEntry name="scan_fetch_size">10</PropertyEntry>
<PropertyEntry name="remote_source_name">oracle999</PropertyEntry>
<PropertyEntry name="lr_parallel_scan">false</PropertyEntry>
<PropertyEntry name="pds_use_tnsnames">false</PropertyEntry>
<PropertyEntry name="pds_sql_connection_pool_size">15</PropertyEntry>
</ConnectionProperties>'
WITH CREDENTIAL TYPE 'PASSWORD' USING
'<CredentialEntry name="credential">
<user>C##LR_USER</user>
<password>HXEHana1</password>
</CredentialEntry>';

-- Grant _SYS_REPO some rights so that .hdbreplicationtasks can create Virtual Tables and Remote Subscriptions.
GRANT CREATE VIRTUAL TABLE ON REMOTE SOURCE "oracle" TO _SYS_REPO;
GRANT CREATE REMOTE SUBSCRIPTION ON REMOTE SOURCE "oracle" TO _SYS_REPO;
```

At this point, you are done configuring your Oracle DB for realtime replication, set up a replication user, and created a remote source in HANA.

### Create a View for LogReader User

The one manual step that needs to be done for `C##LR_USER` is to create a view called `RA_ALL_USERS_VIEW`.  This can be done as `sys` in either `sqlplus` or `sqldeveloper`:

```sql
CREATE VIEW C##LR_USER.RA_ALL_USERS_VIEW (USER#, NAME, PASSWORD, TYPE#, ASTATUS) AS SELECT USER#, NAME, NULL, TYPE#, ASTATUS FROM SYS.USER$;
```

### Create some dummy data in Oracle

Connect as `C##LR_USER` using either `sqlplus` or `sqldeveloper`.  For reference, here is an example `sqldeveloper` connection.

   | Property | Value |
   | --- | --- |
   | Connection Name | `LogReader user on ORCLCDB` (Or whatever you want to call it) |
   | Username | `C##LR_USER` (Case-sensitive) |
   | Password | `HXEHana1` |
   | Role | `default` |
   | Hostname | `192.168.99.100` or `localhost` or wherever your container runs |
   | Service name | `ORCLCDB.localdomain` |

Run the following SQL Commands to create a table and a few sample entries:

   ```sql
   CREATE TABLE customers  
   ( customer_id number(10) NOT NULL,  
     customer_name varchar2(50) NOT NULL,  
     city varchar2(50)  
   );

   INSERT INTO customers (customer_id, customer_name, city) VALUES (1,'Mike','Memphis');
   INSERT INTO customers (customer_id, customer_name, city) VALUES (2,'Eric','St. Louis');
   INSERT INTO customers (customer_id, customer_name, city) VALUES (3,'Derek','Philadelphia');

   COMMIT;
   ```

  You should now be able to expand the `oracle` entry under Remote Sources and see a list of Schemas, as well as see the `CUSTOMER` Table under the `C##LR_USER` Schema.  *(In a real-world use case, your data would usually be under a different DB Schema, however this is a simple example.)*

