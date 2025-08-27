# 📘 Check-Delegation.ps1

## Overview
`Check-Delegation.ps1` is a PowerShell script designed to check Active Directory accounts (users or computers) for their **delegation type**.  

It supports two modes:
- **Targeted Mode** → Scan specific accounts via `-InputFile` or `-Accounts`.  
- **Full Scan Mode** → Use `-All` to scan every user and computer in AD (with progress bar).  

It determines whether accounts are configured for:

- **Unconstrained Delegation**  
- **Constrained Delegation**  
- **None** (no delegation detected by the script)

It also reports whether the account is **enabled** or **disabled**.

---

## 🔍 How Delegation Is Detected
The script checks the following:

1. **Unconstrained Delegation**  
   - `UF_TRUSTED_FOR_DELEGATION (0x80000)` flag set in `userAccountControl`.  
   - `msDS-AllowedToDelegateTo` empty.

2. **Constrained Delegation**  
   - `msDS-AllowedToDelegateTo` contains one or more values.

3. **None**  
   - Neither unconstrained nor constrained delegation found.  
   - ⚠️ Resource-Based Constrained Delegation (RBCD) is not checked.

---

## ⚙️ Parameters
- **`-InputFile`** : Path to a file containing account names (one per line).  
- **`-Accounts`** : One or more account names provided inline.  
- **`-All`** : Scan all AD users and computers (progress bar shown).  
- **`-NoColor`** : Disable colored output.  

❗ Running with **no arguments** shows usage instructions.

---

## 📑 Usage Examples

### Example 1: Check accounts from a file
```powershell
PS C:\> .\Check-Delegation.ps1 -InputFile accounts.txt
