# Set up a Remote Source from HANA Express Container to Oracle Container

With your HANA Express Docker container, DP Agent container, and Oracle DB Container set up as described, you should be able to create a Remote Source as described here.

## Prerequisites for this Remote Source

- Running Docker Compose Stack as described previously
- DP Agent Registered as described previously with the `OracleLogReaderAdapter` Adapter registered.
- Can create a connection your HANA Express Tenant DB (HXE) in Eclipse HANA Tools/HANA Studio.

1. In HANA Studio, expand the Provisioning section of your HANA Express system, and right-click on Remote Sources and select 'New Remote Source...'

2. For a **Pluggable Database**, provide the following values for the properties listed below:

   | Property | Value |
   | --- | --- |
   | Source Name | `oracle` or whatever you want |
   | Adapter Name | `Oracle Log Reader` |
   | Source Location | `agent (dpagent_dpagent)` |
   | Host | `oracle` |
   | Port Number | `1521` |
   | Service Name | `ORCLCDB.localdomain` |
   | Oracle supplemental logging level | `database` |
   | Credentials Mode | `Technical User` |
   | All User Name Fields in Red (Case Sensitive) | `C##LR_USER` |
   | All Password Fields in Red | `HXEHana1` |

   If you do not need realtime replication and prefer to use the **Pluggable Database**, provide these values instead:

   | Property | Value |
   | --- | --- |
   | Source Name | `oracle` or whatever you want |
   | Adapter Name | `Oracle Log Reader` |
   | Source Location | `agent (dpagent_dpagent)` |
   | Host | `oracle` |
   | Port Number | `1521` |
   | Service Name | `ORCLPDB1.localdomain` |
   | Credentials Mode | `Technical User` |
   | All User Name Fields in Red (Case Sensitive) | `C##LR_USER` |
   | All Password Fields in Red | `HXEHana1` |

   Press Control+S to Save and ensure that you get a message stating "Connection to remote source established".

   You should now be able to view the Oracle Schemas under `Remote Sources` in HANA Studio.
