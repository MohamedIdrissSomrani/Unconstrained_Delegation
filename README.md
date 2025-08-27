# 📘 Check-Delegation.ps1

## Overview
`Check-Delegation.ps1` is a PowerShell script designed to check Active Directory accounts (users or computers) for their **delegation type**.  
It can be used in two modes:

- **Targeted Mode** → Check only accounts you specify (via file or parameters).  
- **Proactive Mode** → If no accounts are given, scan **all users and computers in AD** automatically.

It determines whether accounts are configured for:

- **Unconstrained Delegation**  
- **Constrained Delegation**  
- **None** (no delegation detected by the script)

It also reports whether the account is **enabled** or **disabled**.

---

## 🔍 How Delegation Is Detected
The script checks the following:

1. **Unconstrained Delegation**  
   - Looks for the `UF_TRUSTED_FOR_DELEGATION (0x80000)` flag in `userAccountControl`.  
   - Ensures that `msDS-AllowedToDelegateTo` is empty.

2. **Constrained Delegation**  
   - Checks whether the attribute `msDS-AllowedToDelegateTo` is present and has one or more values.

3. **None**  
   - If neither unconstrained nor constrained delegation is found, the script marks the account as `None`.  
   - ⚠️ This includes accounts that use **Resource-Based Constrained Delegation (RBCD)**, since the script does not currently test the `msDS-AllowedToActOnBehalfOfOtherIdentity` attribute.

---

## ⚙️ Parameters
- **`-InputFile`** : Path to a text file containing a list of accounts (one per line).  
- **`-Accounts`** : Array of account names passed directly on the command line.  
- **`-NoColor`** : Switch to disable colored output (useful for logging or exporting).  

If neither `-InputFile` nor `-Accounts` is provided, the script automatically queries **all AD users and computers**.

---

## 📑 Usage Examples

### Example 1: Check accounts from a file
```powershell
PS C:\> .\Check-Delegation.ps1 -InputFile accounts.txt
```

### Example 2: Check specific accounts inline
```powershell
PS C:\> .\Check-Delegation.ps1 -Accounts user1, user2, SERVER01$
```

### Example 3: Proactive scan of all AD accounts
```powershell
PS C:\> .\Check-Delegation.ps1
```

### Example 4: Disable colored output
```powershell
PS C:\> .\Check-Delegation.ps1 -NoColor
```

---

## 📝 Output
The script prints results in table format:

| Account     | Type     | Enabled | DelegationType |
|-------------|----------|---------|----------------|
| user1       | User     | True    | None           |
| user2       | User     | True    | Constrained    |
| SERVER01$   | Computer | True    | Unconstrained  |
| badentry    | Not Found|         | N/A            |

Delegation types are color-coded (unless `-NoColor` is used):  
- **Red** → Unconstrained  
- **Yellow** → Constrained  
- **Green** → None  
- **Gray** → Errors or N/A  

---

## ⚠️ Notes
- `"None"` does not necessarily mean the account has no delegation risk; it only means no **classic unconstrained or constrained delegation** was detected.  
- **Resource-Based Constrained Delegation (RBCD)** is not checked.  
- `"Not Found"` indicates the account could not be resolved in Active Directory.  
- `"Error"` entries show lookup or permission issues.  

---

## ✅ Summary
`Check-Delegation.ps1` now supports **proactive AD scanning**, making it useful for security audits, pentests, and defensive hardening efforts.
