# Configuring Data Provisioning Agent

1. Start the DP Agent Configurtation CLI Tool

   *Note, replace `hana-dp_dpagent_1` with whatever the name of the container is based on how you launched with either Docker or Docker Compose.  You can run `docker ps` to get a list of your running containers if you are not sure.*

   ```bash
   docker exec -ti hana-dp_dpagent_1 bash -c "/home/dpagent/dataprovagent/bin/agentcli.sh --configAgent"
   ```

2. If successful, you will get this menu:

   ```txt
   ************************************************************
                    DPAgent Configuration Tool
   ************************************************************
   1. Agent Status
   2. Start or Stop Agent
   3. Agent Preferences
   4. Remote Source Credentials
   5. SSL Keystores
   6. SAP HANA Connection
   7. Agent Registration
   8. Adapter Registration
   9. Custom Adapters
   10. Agent & Adapter Versions
   q. Quit
   b. Back
   ************************************************************
   Enter Option:
   ```

3. Select option 6 (SAP HANA Connection)

   ```txt
   ************************************************************
                       SAP HANA Connection
   ************************************************************
   1. Connect to SAP HANA on Cloud (HTTP/HTTPS)
   2. Connect to SAP HANA on Premise (TCP)
   3. Connect to SAP HANA via JDBC
   q. Quit
   b. Back
   ************************************************************
   Enter Option:
   ```

4. Select option 2 (Connect to SAP HANA on Premise (TCP)) and provide the following property values as prompted:

     | Prompt | Value |
     | --- | --- |
     |Enter Use SSL (requires configuration)|`false`|
     |Enter Host Name|`hxe`|
     |Enter Port Number|`39041`|
     |Enter Agent Admin HANA User|`SYSTEM`|
     |Enter Agent Admin HANA User Password|`Your SYSTEM password`|

     If successful, you should get a message as follows:

     ```txt
     Agent configuration tool is connected to SAP HANA server.

     Press Enter to continue...
     ```

     Press Enter, and then select b for back to previous menu.

5. Select option 7 (Agent Registration)

   ```txt
   ************************************************************
                        Agent Registration
   ************************************************************
   1. Register Agent
   2. Unregister Agent
   q. Quit
   b. Back
   ************************************************************
   ```

6. Select Option 1 (Register Agent) and provide the following property values as prompted:
   | Prompt | Value |
   | --- | --- |
   |Enter Agent Name|`dpagent_dpagent`|
   |Enter Agent Host Name|`dpagent`|

    If successful, you should get a message as follows:

     ```txt
     Agent 'dpagent_dpagent' successfully registered.

     Press Enter to continue...
     ```

     Press Enter, and then select b for back to previous menu.

7. Select 8. Adapter Registration

   ```txt
   ************************************************************
                       Adapter Registration
   ************************************************************
   1. Display Adapters
   2. Register Adapter
   3. Unregister Adapter
   q. Quit
   b. Back
   ************************************************************
   ```

   For reference, these are the Display Adapters available:

   - ABAPAdapter
   - ASEECCAdapter
   - CamelJdbcAdapter
   - DB2ECCAdapter
   - DB2MainframeAdapter
   - FileAdapter
   - HanaAdapter
   - ImpalaAdapter
   - MssqlLogReaderAdapter
   - OracleLogReaderAdapter
   - PostgreSQLLogReaderAdapter
   - TeradataAdapter
   - TwitterAdapter

8. Select 2 Register Adapter.  Provide the name of the adapter based on the data source type you will be connecting to.  For example, for Oracle, type `OracleLogReaderAdapter`.  If successful, you should get a confirmation like this:

   ```txt
   Adapter 'OracleLogReaderAdapter' successfully registered.

   Press Enter to continue...
   ```

9. At this point, you can either register additional adapter types, or choose q to quit the CLI configuration tool.
