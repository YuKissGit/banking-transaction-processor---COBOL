# Banking Transaction Processor - COBOL

## Processor introduction:

At the end of each day, the bank processes all transactions submitted during the day to update customer account balances.
The program ensures that only valid transactions are applied, keeps frozen or non-existent accounts unchanged, and provides a clear audit trail for errors while updating balances for active accounts.

**input**:
1. Customer Accounts (ACCT-MASTER) – Each account has:
    Account ID, Account holder name, Current balance, Account status (active or frozen)
2. Daily Transactions (TRANS-FILE) – Each transaction includes:
    Account ID, Transaction type: Deposit (D) or Withdrawal (W), Transaction amount

**Processing Rules**:
* Only accounts that exist in the master account list can be processed. Transactions for missing accounts are rejected.
* Frozen accounts (AM-STATUS = F) cannot process any deposits or withdrawals. Any transaction for a frozen account is rejected.
* Deposits (D) increase the account balance by the transaction amount.
* Withdrawals (W) decrease the account balance, but only if the account has sufficient funds. Withdrawals that exceed the current balance are rejected.
* Transactions with invalid types or zero amounts are rejected.

**Output**:
1. Updated Accounts (ACCT-NEW) – All valid transactions are applied, and the updated balances are saved.
2. Error Log (ERROR-FILE) – Transactions that fail validation are recorded with the reason (e.g., “Account Frozen”, “Insufficient Funds”, “Account Not Found”).
3. End-of-Day Report (REPORT-FILE) – A summary including the total number of transactions processed, successful transactions, failed transactions, total deposits, and total withdrawals.
---
## How to run COBOL (GnuCOBOL on macOS)

### Installation
1. Ensure you have [Homebrew](https://brew.sh/) installed. 
2. Install GnuCOBOL by running:
```
brew install gnu-cobol
```
3. After installation, verify it by checking the version:
```
cobc -v
```

If the installation was successful, you will see output similar to: 

**Note**: You might see an error message at the end saying: 
```
cobc: error: no input files
```
Don't worry, this is normal. The reason is that you only ran the compiler command without providing an input file. 
Since the compiler didn't know what work to do, it reported an error and quit.

### Usage
4. You can view all supported functions and flags by using the help command:
```
cobc -h
```
5. To compile a .cob file into an executable, use the -x flag. You can specify the output filename using the -o flag:
```
cobc -x fileName.cob -o executableFileName
```
6. This will compile your source code and generate a single executable file. 
To run your program, simply execute the generated file:
```
./executableFileName
```
---

## COBOL learning note
