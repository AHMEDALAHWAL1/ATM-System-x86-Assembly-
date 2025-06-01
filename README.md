# 🏧 Al-Ahwal ATM System (x86 Assembly)
**Simulated Banking Terminal with PIN Access, Dual Account Handling, and Transaction History**

Welcome to the **Al-Ahwal ATM System**, a fully functional banking simulation developed entirely in **8086 Assembly Language**. This project simulates a real ATM environment using a DOS-based console, offering secure PIN access, balance checks, deposits, withdrawals, transfers, and a transaction log.

---

## ✨ Features

- 🔐 **PIN Security**: 4-digit input (default: `1234`) with validation and lockout after 3 failed attempts
- 💳 **Account Types**: Savings and Wallet with individual balances
- 💰 **Operations**: Deposit, Withdraw, Transfer funds
- 📜 **Transaction History**: Shows last 20 records (type, account, amount)
- 🔄 **Change PIN**: Secure and validated PIN update flow
- 🧡 **Animated Console Interface**: Orange text visuals with animated text display
- 🧠 **Error Handling**: Input validation, max attempts, empty entries

---

## 🧱 Technology Stack

- 💻 **Language**: x86 Assembly (MASM/TASM)
- 💽 **Platform**: DOSBox / 16-bit DOS emulator
- 🏗 **Executable**: `.EXE` or `.COM` file for DOS

---

## 📁 Files

- `AL_AHWAL_ATM.ASM` — Complete source code
- `README.md` — Project documentation
- (Optional) `AL_AHWAL_ATM.EXE` — Compiled output

---

## ▶️ How to Run

> Prerequisites:
> - [DOSBox](https://www.dosbox.com/)
> - [TASM](https://winworldpc.com/product/turbo-assembler/31x) or MASM

### 🛠 Assemble and Link:

```bash
tasm AL_AHWAL_ATM.asm
tlink AL_AHWAL_ATM.obj




🎮 Sample Flow
Enter your PIN (default: 1234)

Choose from 7 options:

Check Balance

Deposit

Withdraw

Transfer

View History

Change PIN

Exit

Perform operations and view updated balances

System tracks up to 20 transactions per session

⚠️ Limitations
No file storage (data resets after exit)

Only one user profile (fixed PIN)

History is RAM-based and capped at 20 entries

16-bit only: requires DOSBox or legacy OS support

Name: Ahmed Abdullah Ahmed Al-Ahwal
Student ID: TP077300
University: Asia Pacific University (APU)
Course: Assembly Programming, 2025
Project Type: Educational Simulation

