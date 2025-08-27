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

Optionally, results can be exported to a **CSV file** with the `-OutFile` parameter.

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
- **`-OutFile`** : Path to save results in CSV format (optional).  
- **`-NoColor`** : Disable colored output.  

❗ Running with **no arguments** shows usage instructions.

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

### Example 3: Full proactive scan of all AD accounts
```powershell
PS C:\> .\Check-Delegation.ps1 -All
```

### Example 4: Save results to CSV
```powershell
PS C:\> .\Check-Delegation.ps1 -All -OutFile results.csv
```

### Example 5: Disable colored output
```powershell
PS C:\> .\Check-Delegation.ps1 -All -NoColor
```

---

## 📝 Output
Results are displayed in a table format:

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

When **`-OutFile`** is specified, results are also written to the chosen **CSV file**.

---

## ✅ Summary
`Check-Delegation.ps1` quickly identifies delegation configurations in AD.  
With the new `-OutFile` option, results can be saved to **CSV** for further analysis, reporting, or tracking across runs.
