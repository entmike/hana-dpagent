# Obtaining XSC Delivery Units

HANA Express Docker containers unfortunately does not come with the required XS Classic packages required for SDI.  Also, the `SDI.tgz` package from the HANA Express Download Manager has an install script that does not work in the HXE Docker container.  We can still install thise with a little bit of effort.

***Note:** If you have an SAP Support Marketplace ID, a license to use HANA, and download access, it's much easier to obtain these delivery units via that channel.  The following instructions assume you will obtain what you need via HANA Express Download Manager as an alternative.*

## Create a `packages` Folder

Create a designated packages folder somewhere on your computer or Docker server.  We will call it `/packages` but wherever you choose to place it is up to you.

## Get `HANAIMDP.tgz` Delivery Unit

1. Download `SDI.tgz` from HANA Express Download Manager.
2. Using `tar` or a program like 7-Zip on Windows, extract the contents of `SDI.tgz`.  (If using 7-Zip, you may then need to extract the `sdi.tar` inside of it.)
3. Enter `HANA_EXPRESS_20/DATA_UNITS/SAP_HANA_SDI_20` folder.
4. Copy `HANAIMDP.tgz` to your `/packages` folder.
5. Delete the `SDI.tgz` and extracted folder contents as we've obtained the delivery unit we are after.

## Get all the other XS Classic Delivery Units available

1. Download `Server only installer` (`hxe.tgz`) from HANA Express Download Manager (Make sure you are under the `Binary Installer` Image type if you are using the GUI.)
2. Using `tar` or a program like 7-Zip on Windows, extract the contents of `hxe.tgz`.  (If using 7-Zip, you may then need to extract the `hxe.tar` inside of it.)
3. Navigate to `HANA_EXPRESS_20/DATA_UNITS/HDB_SERVER_LINUX_X86_64/server` and extract `CONTENT.TGZ`.
4. Navigate to `global/hdb/auto_content` and copy all `.tgz` files to your `/packages` folder.
5. Delete `hxe.tgz` and all the extracted folder contents as we've obtained the delivery units we need.
