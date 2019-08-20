# Installing SDI packages to HANA Express Docker

## Problem

Installing SDI to HANA Express Docker container can be tricky.  While you can use the HXE Download Manger to get the SDI package, it will not install normally.  The reason is, that the Docker edition does not contain the pre-requisite XS Classic packages and will fail.

## Workaround

You will either need to download from SAP Support Marketplace the following packages, or pull them out of a HANA Express VM Installation.

Regardless of how you obtain the files, copy the following files to a directory on your host machine:

- AHCO_INA_SERVICE.tgz
- HANA_DT_BASE.tgz
- HANA_IDE_CORE.tgz
- HANA_TA_CONFIG.tgz
- HANA_UI_INTEGRATION_1_SVC.tgz
- HANA_UI_INTEGRATION_2_CONTENT.tgz
- HANA_XS_BASE.tgz
- HANA_XS_DBUTILS.tgz
- HANA_XS_EDITOR.tgz
- HANA_XS_IDE.tgz
- HANA_XS_LM.tgz
- HDC_ADMIN.tgz
- HDC_BACKUP.tgz
- HDC_IDE_CORE.tgz
- HDC_SEC_CP.tgz
- HDC_SYS_ADMIN.tgz
- HDC_XS_BASE.tgz
- HDC_XS_LM.tgz
- SAP_WATT.tgz

In Eclipse, import the following packages in this order either via HANA Studio or regi command:

1. `HANA_DT_BASE.tgz`
2. `HANA_IDE_CORE.tgz`
3. `HANA_XS_BASE.tgz`
4. `HANA_XS_IDE.tgz`
5. `HANA_XS_EDITOR.tgz`
6. `SAP_WATT.tgz`
7. `HDC_IDE_CORE.tgz`
8. `SAPUI5_1.tgz` (This one takes some time)
9. `HANAIMDP.tgz` (from SDI.tgz file)

Example regi command:

```bash
cd /hana/shared/HXE/global/hdb/content

/usr/sap/HXE/HDB90/exe/regi import SAPUI5_1.tgz  --host=hxe:39041 --user=SYSTEM --password=HXEHana1`
```

Next, copy the `SDI.tgz` file into the same directory.

Start your HXE Docker Image with the following volume flag `-v /c/Users/RHOWLES/data/hana-packages:/usr/sap/HXE/SYS/global/hdb/content`

`cd /usr/sap/HXE/SYS/global/hdb/content`

```bash
export REGI_DIR=/hana/shared/HXE/global/hdb/content

export REGI_DIR=/usr/sap/HXE/SYS/global/hdb/content

/usr/sap/HXE/HDB90/exe/regi import SAP_WATT.tgz HDC_IDE_CORE.tgz HANA_XS_EDITOR.tgz HANA_IDE_CORE.tgz HANA_XS_IDE.tgz  --host=hxe:39041 --user=SYSTEM --password=HXEHana1

```

`tar -xvf sdi.tgz`


`cd cd HANA_EXPRESS_20`

`./install_sdi.sh`

```bash
hxeadm@hxe:/usr/sap/HXE/SYS/global/hdb/content/HANA_EXPRESS_20> ./install_sdi.sh
Enter HANA instance number [90]:
Enter local host name [hxe]:

Enter System database user (SYSTEM) password :

Enter name of tenant database to add smart data integration [HXE]:

Enter "HXE" database system user (SYSTEM) password :


##############################################################################
# Summary before execution                                                   #
##############################################################################
HANA, express edition installer     : /usr/sap/HXE/SYS/global/hdb/content/HANA_EXPRESS_20
  Component(s) to install           : SAP HANA smart data integration (SDI)
  HANA system ID                    : HXE
  HANA instance number              : 90
  Host name                         : hxe
  System database pasword           : ********
  Tenant database to add SDI        : HXE
  Tenant database password (SYSTEM) : ********
Proceed with installation? (Y/N) :
```

From HXE Tenant DB, run the following commands to make XSC reference your HXE TenantDB:

```sql

ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'database') SET ('public_urls', 'http_url') = 'http://192.168.99.100:8090' WITH RECONFIGURE;
ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'database') SET ('public_urls', 'http_url') = 'https://192.168.99.100:4390' WITH RECONFIGURE;
ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'http_url') = 'http://192.168.99.100:8090' WITH RECONFIGURE;
ALTER SYSTEM ALTER CONFIGURATION ('xsengine.ini', 'system') SET ('public_urls', 'https_url') = 'http://192.168.99.100:4390' WITH RECONFIGURE;

```

## URLs for Data Provisioning:

|Page|URL|
|---|---|
|Design Time Object Monitor|`http://[docker host]:8090/sap/hana/im/dp/monitor/index.html?view=IMDesignTimeObjectMonitor`|
|Agent Monitor|`http://[docker host]:8090/sap/hana/im/dp/monitor/index.html?view=DPAgentMonitor`|
|Subscriptin Monitor|`http://[docker host]:8090/sap/hana/im/dp/monitor/index.html?view=DPSubscriptionMonitor`|
|Task Monitor|`http://[docker host]:8090/sap/hana/im/dp/monitor/index.html?view=IMTaskMonitor`|
|Schedule Data Provisioning Tasks|`http://[docker host]:8090/sap/hana/xs/admin/jobs/#/package/sap.hana.im.dp.monitor.jobs/job/scheduleTask`|
