# HANA Data Provisioning Agent Docker Image

Builds a Docker Image with Data Provisioning Agent pre-installed with some common JAR files included.  Since `HXEDownloadManager_linux.bin` is used to actually download the software, it will pull whatever the latest is available from SAP (for instance, 2.0 SP3 or SP4 etc)  So tag your builds with something appropriate if needed.

## Prerequisites

- Download and place `sapjvm-8.1.055-linux-x64.zip` in the files directory.  The ZIP files is too big for Github and when I tried using Git LFS it was a horrible experience for me.

## Building

   1. `git clone https://github.com/entmike/hana-dpagent.git`
   2. Copy `sapjvm-8.1.055-linux-x64.zip` to `files` directory.
   3. `cd hana-dpagent`
   4. `docker build -t dpagent-image .`

## Running Example in Docker Compose

Note: This example assumes you are running an existing HANA Express (2.0 SP3 in this case) with a hostname of `hxe` and a pre-existing volume named `hxedev`.

```yaml
version: '2'
    
services:
    
  dpagent:
    image: dpagent
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

