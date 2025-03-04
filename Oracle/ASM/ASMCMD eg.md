### **ASMCMD Commands with Examples**  

Below is a collection of commonly used **ASMCMD** commands with practical examples for **Oracle ASM** management.

---

## **1. List ASM Disk Groups**
### **Command:**  
```bash
ASMCMD> lsdg
```
### **Example Output:**
```
State    Type    Rebal  Name
MOUNTED  EXTERN N      DATA
MOUNTED  NORMAL N      ARCH
```
### **Additional Options:**  
- **Include dismounted disk groups:**  
  ```bash
  ASMCMD> lsdg --discovery
  ```
- **List disk groups across all cluster nodes:**  
  ```bash
  ASMCMD> lsdg -g --discovery
  ```

---

## **2. List ASM Disks**
### **Command:**  
```bash
ASMCMD> lsdsk -k
```
### **Example Output:**
```
Path               Group_Name  Size_MB  Free_MB  State
/dev/oracleasm/disks/DISK1  DATA      10000    5000    NORMAL
/dev/oracleasm/disks/DISK2  ARCH      8000     3000    NORMAL
```
### **Additional Options:**  
- **List disks of a specific disk group (e.g., CDATA) with free and total space:**  
  ```bash
  ASMCMD> lsdsk -k -G CDATA
  ```
- **List candidate disks only:**  
  ```bash
  ASMCMD> lsdsk --candidate -k
  ```

---

## **3. Get Attributes of ASM Disk Groups**
### **Command:**  
```bash
ASMCMD> lsattr -lm
```
### **Example Output:**
```
Group_Name    Name                  Value      RO   Sys
DATA          au_size               1048576    Y    Y
ARCH          access_control.enabled FALSE      N    Y
```
### **Additional Options:**  
- **List attributes of a specific disk group (e.g., DMARCH):**  
  ```bash
  ASMCMD> lsattr -lm -G DMARCH
  ```

---

## **4. Unmount a Disk Group**
### **Command:**  
```bash
ASMCMD> umount ARCH
```
### **Additional Options:**  
- **Unmount all disk groups on a node:**  
  ```bash
  ASMCMD> umount -a
  ```

---

## **5. Mount a Disk Group**
### **Command:**  
```bash
ASMCMD> mount ARCH
```
### **Additional Options:**  
- **Mount all disk groups on a node:**  
  ```bash
  ASMCMD> mount -a
  ```

---

## **6. Rebalance a Disk Group**
### **Command:**  
```bash
ASMCMD> rebal --power 8 ARCH
```
### **Monitor Rebalancing Progress:**  
```bash
ASMCMD> lsop
```
### **Example Output:**
```
Group_Name Pass     State      Power  EST_WORK  EST_RATE  EST_TIME
ARCH       REBALANCE DONE       8      0        0         0
```

---

## **7. Retrieve ASM Password File**
### **Get the password file location of a database (e.g., DBACLASS):**  
```bash
ASMCMD> pwget --dbuniquename DBACLASS
```
### **Example Output:**
```
+CDATA/DBACLASS/PASSWORD/pwddbaclass.256.899912377
```

### **Get ASM password file location:**
```bash
ASMCMD> pwget --asm
```
### **Example Output:**
```
+MGMT/orapwASM
```

---

## **8. View ASM Version**
### **Command:**  
```bash
ASMCMD> showversion
```
### **Example Output:**
```
ASM version : 12.1.0.2.0
```

---

## **9. Retrieve ASM SPFILE Location**
### **Command:**  
```bash
ASMCMD> spget
```
### **Example Output:**
```
+MGMT/DBACLASS-cluster/ASMPARAMETERFILE/registry.253.899644763
```

---

## **10. Backup ASM SPFILE**
### **Command:**  
```bash
ASMCMD> spbackup +MGMT/DBACLASS-cluster/ASMPARAMETERFILE/registry.253.899644763 /home/oracle/asmspfile.ora
```

---

## **11. Check Connected Clients to a Disk Group**
### **Command:**  
```bash
ASMCMD> lsct DMARCH
```
### **Example Output:**
```
DB_Name    Status    Software_Version    Compatible_version    Instance_Name    Disk_Group
DBACLASS   CONNECTED 12.1.0.2.0          12.1.0.2.0            DBACLASS1        DMARCH
```

---

## **12. Get ASM Disk String**
### **Command:**  
```bash
ASMCMD> dsget
```
### **Example Output:**
```
parameter:ORCL:*
profile:ORCL:*
```

---

## **13. List ASM Users with Passwords**
### **Command:**  
```bash
ASMCMD> lspwusr
```
### **Example Output:**
```
Username    sysdba    sysoper    sysasm
SYS        TRUE      TRUE       TRUE
ASMSNMP    TRUE      FALSE      FALSE
```

---

## **14. List Open Files in a Disk Group**
### **Command:**  
```bash
ASMCMD> lsof -G ARCH
```
### **Example Output:**
```
File Name                                Size_MB
+ARCH/ONLINELOG/group_1.123.899912377    200
+ARCH/DATAFILE/users.256.899912377       500
```

---

## **15. List Open Files Related to a Database**
### **Command:**  
```bash
ASMCMD> lsof --dbname DBACLASS
```

---

## **16. Check if ASM Filter Driver (AFD) is Enabled**
### **Command:**  
```bash
ASMCMD> afd_state
```
### **Example Output:**
```
ASMCMD-9526: The AFD state is 'NOT INSTALLED' and filtering is 'DEFAULT' on host 'b20e4bay01'
```

---

## **17. List ASM Filter Driver Disks (If Enabled)**
### **Command:**  
```bash
ASMCMD> afd_lsdsk
```

---

## **18. Get ASM Filter Driver Disk String**
### **Command:**  
```bash
ASMCMD> afd_dsget
```
### **Example Output:**
```
AFD discovery string: ORCL:*
```

---
