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
   2. Copy `sapjvm-8.1.055-linux-x64.zip` to `files` directory.
   3. `cd hana-dpagent`
   4. `docker build -t dpagent-image .`

## Running in Docker

`docker run -d -p 5050:5050 --rm --name dpagent dpagent-image`

## Accessing the Data Provisioning Agent CLI configuration menu

`docker exec -ti dpagent bash -c "/home/dpagent/dataprovagent/bin/agentcli.sh --configAgent"`

## Running Example in Docker Compose

Realistically in a containerized scenario, you'll simply just want to have DP Agent and HXE running in same Docker network.  Docker Compose makes this simple and easy for the 2 containers to communicate internally.

Note: This example assumes:

  1. You built your Docker Image called `dpagent-image`
  2. You are running an existing HANA Express (2.0 SP3 in this case) with a hostname of `hxe` and a pre-existing docker volume named `hana-express`.

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

