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

The following is a very bare-bones simple example of how to run the Data Provisioning Agent in a single docker container.  In this example, the container is removed after it is stopped and no data or logs are persisted.

### Start a container in Docker

`docker run -d -p 5050:5050 --rm --name dpagent dpagent-image`

### Accessing the Data Provisioning Agent CLI configuration menu

`docker exec -ti dpagent bash -c "/home/dpagent/dataprovagent/bin/agentcli.sh --configAgent"`

## Simple Running Example in Docker Compose

Realistically in a containerized scenario, you'll simply just want to have DP Agent and HXE running in same Docker network.  Docker Compose makes this simple and easy for the 2 containers to communicate internally.

Note: This example assumes:

  1. You built your Docker Image called `dpagent-image`
  2. You are running an existing HANA Express (2.0 SP3 in this case) with a hostname of `hxe` and a pre-existing docker volume named `hana-express`.

     *(Simply run `docker volume create hana-express` if you have not)*

```yaml
version: '2'

services:

  dpagent:
    image: dpagent-image
    hostname: dpagent

  hxehost:
    image: store/saplabs/hanaexpress:2.00.036.00.20190223.1
    hostname: hxe
    volumes:
      - hxedev:/hana/mounts
    command: --agree-to-sap-license --master-password ${HXE_MASTER_PASSWORD}

volumes:
  hxedev:
    external:
      name: hana-express
```

### Configuring Data Provisioning Agent and Adapter(s) from CLI in this Docker Compose Stack

To configure the DP Agent via the CLI Tool, read [instructions here](DPAgentConfig.md).

## Running Example in Docker Compose with Oracle DB

This next example illustrates a similar Docker Compose stack with the addition of an Oracle 12 Database that can be used by the DP Agent and HANA Express Containers for an end-to-end sandbox to play with Data Provisioning Agent and SDA.  After all, this example Docker Compose stack is not a complete self-contained working example if it did not contain an example Data Source, right?

**Note:** This example assumes:

  1. You built your Docker Image called `dpagent-image`
  2. You are running an existing HANA Express (2.0 SP3 in this case) with a hostname of `hxe` and a pre-existing docker volume named `hana-express`.
  
     *(Simply run `docker volume create hana-express` if you have not)*

  3. You have a pre-existing docker volume named `oracle-db`.

     *(Simply run `docker volume create oracle-db` if you have not)*

  4. You have a Docker Hub login and have subscribed to the [Oracle DB image](https://hub.docker.com/_/oracle-database-enterprise-edition)

```yaml
version: '2'

services:

  dpagent:
    image: dpagent-image
    hostname: dpagent

  hxe:
    image: store/saplabs/hanaexpress:2.00.036.00.20190223.1
    hostname: hxe
    volumes:
      - hxedev:/hana/mounts

    ports:
      - 39041:39041
      - 39017:39017
      - 39013:39013
      - 39015:39015
      - 8090:8090
    command: --agree-to-sap-license --master-password ${HXE_MASTER_PASSWORD}

  oracle:
    image: store/oracle/database-enterprise:12.2.0.1-slim
    hostname: oracle
    ports:
      - 1521:1521
    volumes:
      - oracle-db:/ORCL

volumes:
  hxedev:
    external:
      name: hxedev

  oracle-db:
    external:
      name: oracle-db

```

### Option 1: Connecting to Oracle DB Container's ORCLPDB1 in sqlplus as sysdba

```bash
docker exec -ti hana-dp_oracle_1 /bin/bash
sqlplus sys/Oradoc_db1@ORCLPDB1 as sysdba
```

### Option 2: Set Up a sqldeveloper Connection as sysdba

| Property | Value |
| --- | --- |
| Connection Name | Whatever you want |
| Username | `sys` (Case-sensitive) |
| Password | `Oradoc_db1` |
| Hostname | `192.168.99.100` or `localhost` or wherever your container runs |
| Service name | `ORCLPDB1.localdomain` |

### Set up Oracle User

Once your Docker Compose stack is running, the following SQL in eithe sqlplus or sqldeveloper:

```sql
-- Set up Oracle User
CREATE USER DPTEST IDENTIFIED BY HXEHana1;
GRANT CONNECT TO DPTEST;

-- Grant Access to Sample HR Schema
BEGIN
   FOR R IN (SELECT owner, table_name FROM all_tables WHERE owner='HR') LOOP
      EXECUTE IMMEDIATE 'grant select on '||R.owner||'.'||R.table_name||' to DPTEST';
   END LOOP;
END;
```

### Set Up a sqldeveloper Connection as DPTEST

| Property | Value |
| --- | --- |
| Connection Name | Whatever you want |
| Username | `DPTEST` (Case-sensitive) |
| Password | `HXEHana1` |
| Hostname | `192.168.99.100` or `localhost` or whatever host your container runs on |
| Service name | `ORCLPDB1.localdomain` |

## Set up a Remote Source from HANA Express Container to Oracle Container

With your HANA Express Docker container, DP Agent container, and Oracle DB Container set up as described, you should be able to create a Remote Source as described here.

### Prerequisites for this Remote Source

- Running Docker Compose Stack as described previously
- DP Agent Registered as described previously with the `OracleLogReaderAdapter` Adapter registered.
- Can create a connection your HANA Express Tenant DB (HXE) in Eclipse HANA Tools/HANA Studio.

1. In HANA Studio, expand the Provisioning section of your HANA Express system, and right-click on Remote Sources and select 'New Remote Source...'

2. Provide the following values for the properties listed below:

   | Property | Value |
   | --- | --- |
   | Source Name | `oracle` or whatever you want |
   | Adapter Name | `Oracle Log Reader` |
   | Source Location | `agent (dpagent_dpagent)` |
   | Host | `oracle` |
   | Port Number | `1521` |
   | Service Name | `ORCLPDB1.localdomain` |
   | Credentials Mode | `Technical User` |
   | All User Name Fields in Red (Case Sensitive) | `DPTEST` |
   | All Password Fields in Red | `HXEHana1` |

   Press Control+S to Save and ensure that you get a message stating "Connection to remote source established".

  You should now be able to expand the `oracle` entry under Remote Sources and see a list of Schemas, as well as see Tables under the `HR` Schema.
  
