# HANA Data Provisioning Agent Docker Image

Builds a Docker Image with Data Provisioning Agent pre-installed with some common JAR files included.  Since `HXEDownloadManager_linux.bin` is used to actually download the software, it will pull whatever the latest is available from SAP (for instance, 2.0 SP3 or SP4 etc)  So tag your builds with something appropriate if needed.

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

## Running Example in Docker Compose

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

