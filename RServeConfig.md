# RServe Quick Setup
This page explains how to create a Docker Image running Rserve on R `3.5.2`.  Note that SAP may not support this version formally, however I have had no problems running it myself from HANA.  The official supported versions by SAP can be found on this Note: https://launchpad.support.sap.com/#/notes/2185029.  At the time of this writing, it claims only support to 3.2, however again, I have not had problems on `3.5.2`.

## Building your Docker Image

1. Create the following `Dockerfile`:

```Dockerfile
FROM r-base:3.5.2
COPY . /scripts
WORKDIR /scripts

#Expose port 6311
EXPOSE 6311
CMD ["Rscript","start.R"]
```

2. In the same folder, create `start.R`:

```R
#Install Rserve
install.packages('Rserve',,"http://rforge.net/",type="source")

#Include Rserve library
library(Rserve)
#Start Rserve
run.Rserve(config.file ="Rserv.conf") # Port can also be specified in the configuration file.
```

3. Finally, create `Rserv.conf`:

```
remote enable
fileio enable
maxinbuf 500000
plaintext enable
control enable
r-control enable
port 6311
```

4. Build your image:
```bash
docker build -t hana-rserve:3.5.2 .
```
## (Optional) Run your image to test:
```bash
docker run --rm -p 6311:6311 hana-rserve:3.5.2
```
## Configure HANA to connect to RServe
This section derived loosely from official SAP Help Documentation here: https://help.sap.com/viewer/a78d7f701c3341339fafe4031b64f015/2.0.05/en-US/49f750dbb683453f9cea5dae900d7dc6.html

As `SYSTEM` user or someone with system privilege `INIFILE ADMIN`, run the following SQL.  Note, that in this example, it assumes that your rserve container has a hostname of `rserve` in this example.  Adapt as you see fit:

1. Add some INI file parameters.
```sql
ALTER SYSTEM ALTER CONFIGURATION ('indexserver.ini', 'database') SET ('calcengine', 'cer_rserve_addresses') = 'reserve:6311' WITH RECONFIGURE;
ALTER SYSTEM ALTER CONFIGURATION ('indexserver.ini', 'database') SET ('calcengine', 'cer_rserve_maxsendsize') = '0' WITH RECONFIGURE;
ALTER SYSTEM ALTER CONFIGURATION ('indexserver.ini', 'database') SET ('calcengine', 'cer_timeout') = '1800' WITH RECONFIGURE;
```
2. Create your Remote Source
```sql
CREATE REMOTE SOURCE "rserve"
    ADAPTER "rserve"
    CONFIGURATION 'server=rserve;port=6311;ssl_mode=disabled';
```
Note, that if you attempt to view this Remote Source in HANA Studio under Data Provisioning, you will get a JDBC 403 error with a 'not supported' reason.  This is fine from what I can tell.

3. Set your user parameter for `RSERVE` to the name of your newly created Remote Source:
```sql
ALTER USER SYSTEM SET PARAMETER RSERVE REMOTE SOURCES = 'rserve';
```
## Test Connection

1. Create a simple test stored procedure:
```sql
CREATE PROCEDURE R_TEST( 
	OUT result TABLE(LINE VARCHAR(2000))
)
LANGUAGE RLANG AS
BEGIN
    result <- as.data.frame(list(LINE = 'Hello World'))
END;
```

2. Run the stored procedure:
```sql
DO
	BEGIN
	DECLARE results TABLE(LINE VARCHAR(2000));
	CALL R_TEST(:results);
	SELECT * FROM :results;
END;
```
If successful, you should receive a `Hello World` back from RServe.
