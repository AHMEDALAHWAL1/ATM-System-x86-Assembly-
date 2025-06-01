.MODEL SMALL
.STACK 100h

.DATA
    welcomeMsg DB '===   WELCOME  TO  AL-AHWAL BANK ATM    ===', 0
    centerCol  EQU 20

    correctPIN DB '1234'
    inputBuffer DB 5, ?, 5 DUP('$')

    attempts     DB 3
    savingsBalance DW 1000
    walletBalance  DW 500

    menuTitleText DB '=== AL-AHWAL ATM MAIN MENU ===', 0
    menuTitleCol  EQU 25

    menuOptions DB 13,10,'1. Check Balance',13,10
                DB '2. Deposit',13,10
                DB '3. Withdraw ',13,10
                DB '4. Transfer ',13,10
                DB '5. Transaction History',13,10
                DB '6. Change PIN',13,10
                DB '7. Exit',13,10,13,10
                DB 'Choose an option (1-7): $'

    ; Transaction history variables
    MAX_TRANSACTIONS EQU 20
    transactionCount DB 0
    transactions DB MAX_TRANSACTIONS * 30 DUP(0) ; Each transaction record is 30 bytes (type:10, account:10, amount:2, padding:8)
    
    ; Transaction type constants
    TRANS_DEPOSIT    DB 'Deposit   $'
    TRANS_WITHDRAW   DB 'Withdraw  $'
    TRANS_TRANSFER   DB 'Transfer  $'
    
    ; Account type constants
    ACC_SAVINGS      DB 'Savings   $'
    ACC_WALLET       DB 'Wallet    $'
    
    msgEnterPIN  DB 13,10,13,10,'Enter 4-digit PIN: $'
    msgSuccess   DB 13,10,13,10,'Access Granted. Welcome!',13,10,13,10,'$'
    msgFail      DB 13,10,'Incorrect PIN. Try again.$'
    msgLocked    DB 13,10,13,10,'Too many attempts. Exiting to start...',13,10,'$'

    msgBalance   DB 13,10,'[123456] Savings: $'
    msgWallet    DB 13,10,'[567890] Wallet: $'
    msgDeposit   DB 13,10,'Enter amount to deposit: $'
    msgWithdraw  DB 13,10,'Enter amount to withdraw: $'
    msgTransfer  DB 13,10,'Enter amount to transfer: RM $'
    msgTransferFrom DB 13,10,'Transfer from:',13,10,'1. Savings to Wallet',13,10,'2. Wallet to Savings',13,10,'3. Cancel',13,10,'Selection: $'
    msgTransferSuccess DB 13,10,'Transfer completed successfully!',13,10,'$'
    msgCancel    DB 13,10,'Operation cancelled. Returning to the main menu...$'
    msgTooMuch   DB 13,10,'Insufficient balance.',13,10,'$'
    msgExit      DB 13,10,'Thank You For Using AL-AHWAL BANK ATM!',13,10,'$'
    msgAnyKey    DB 13,10,'Press any key to continue...$'
    msgHistory   DB 13,10,'=== TRANSACTION HISTORY ===',13,10,'Type       Account    Amount',13,10,'----------------------------',13,10,'$'
    msgNoHistory DB 13,10,'No transactions recorded yet.',13,10,'$'

    msgAccountChoice DB 13,10,'Choose account:',13,10,'1. Savings',13,10,'2. Wallet',13,10,'3. Cancel',13,10,'Selection: $'
    msgInvalidChoice DB 13,10,'Invalid selection. Please enter 1, 2, or 3.$'
    msgInvalidAmount DB 13,10,'Invalid amount. Please enter a numeric value.$'
    msgMaxAttempts DB 13,10,'Maximum attempts reached. Returning to main menu...$'
    msgEmptyAmount DB 13,10,'Please enter an amount.$', 0

    numberBuffer DB 6, ?, 6 DUP('$')

    msgInvalidInput DB 13,10,'Invalid input. Please enter only digits for your PIN.$', 0
    msgEmptyInput DB 13,10,'Input cannot be empty. Please enter a valid PIN.$', 0

    ; Added success messages for deposit and withdrawal
    msgDepositSuccess  DB 13,10,'Deposit completed successfully!',13,10,'$'
    msgWithdrawSuccess DB 13,10,'Withdrawal completed successfully!',13,10,'$'
    
    ; Messages for Change PIN function
    msgCurrentPIN DB 13,10,'Enter current 4-digit PIN: $'
    msgNewPIN     DB 13,10,'Enter new 4-digit PIN: $'
    msgConfirmPIN DB 13,10,'Confirm new 4-digit PIN: $'
    msgPINMismatch DB 13,10,'New PINs do not match. Please try again.$'
    msgPINChanged DB 13,10,'PIN changed successfully!$'
    
    ; Text color constants
    ORANGE_TEXT  EQU 06h     ; Orange color (Brown on old CGA monitors)
    
    ; Add a flag to track which operation we're in
    currentOperation DB 0    ; 1 = Deposit, 2 = Withdraw, 3 = Transfer

.CODE
main proc
    mov ax, @data
    mov ds, ax
    
    ; Set text color to orange at the beginning
    call SetOrangeTextColor
    
    jmp WELCOME_START

WELCOME_START:
    ; Clear screen
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    ; Center the welcome message
    mov ah, 02h
    mov bh, 0
    mov dh, 12
    mov dl, centerCol
    int 10h

    lea si, welcomeMsg
    call AnimatedPrint

    call HoldScreen

    mov attempts, 3
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

PIN_TRY:
    lea dx, msgEnterPIN
    call PrintString

    mov inputBuffer+1, 0
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h

    ; Error Handling for PIN input
    lea si, inputBuffer+2
    mov cx, 4
    mov bx, 0  ; Flag for valid input
    errorLoop:
        mov al, [si]
        cmp al, 13  ; Check for Enter (End of input)
        je doneErrorLoop

        ; Check if the entered character is not a number
        cmp al, '0'
        jb invalidInput
        cmp al, '9'
        ja invalidInput

        ; If it's a number, continue and mark as valid input
        inc si
        loop errorLoop
        jmp doneErrorLoop

    invalidInput:
        lea dx, msgInvalidInput
        call PrintString
        jmp PIN_TRY

    doneErrorLoop:
    ; Check if input is empty
    lea si, inputBuffer+2
    mov al, [si]
    cmp al, 13  ; Enter key pressed without any input
    je emptyInput

    ; Validate PIN
    lea si, inputBuffer+2
    lea di, correctPIN
    mov cx, 4
compareLoop:
    mov al, [si]
    cmp al, [di]
    jne PIN_FAIL
    inc si
    inc di
    loop compareLoop

    jmp PIN_SUCCESS

emptyInput:
    lea dx, msgEmptyInput
    call PrintString
    jmp PIN_TRY

PIN_FAIL:
    dec attempts
    lea dx, msgFail
    call PrintString
    cmp attempts, 0
    jne SkipLock
    jmp PIN_LOCKED
SkipLock:
    jmp PIN_TRY

PIN_SUCCESS:
    lea dx, msgSuccess
    call PrintString
    call HoldScreen
    jmp ATM_MENU

ATM_MENU:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    mov ah, 02h
    mov bh, 0
    mov dh, 5
    mov dl, menuTitleCol
    int 10h

    lea si, menuTitleText
    call AnimatedPrint

    mov ah, 02h
    mov bh, 0
    mov dh, 7
    mov dl, 0
    int 10h

    lea dx, menuOptions
    call PrintString

    call ReadChar

    cmp al, '1'
    jne .next1
    jmp ShowBalance
.next1:
    cmp al, '2'
    jne .next2
    mov currentOperation, 1  ; Set flag for Deposit
    jmp Deposit
.next2:
    cmp al, '3'
    jne .next3
    mov currentOperation, 2  ; Set flag for Withdraw
    jmp Withdraw
.next3:
    cmp al, '4'
    jne .next4
    mov currentOperation, 3  ; Set flag for Transfer
    jmp Transfer
.next4:
    cmp al, '5'
    jne .next5
    jmp ShowHistory
.next5:
    cmp al, '6'
    jne .next6
    jmp ChangePIN
.next6:
    cmp al, '7'
    jne ATM_MENU
    jmp ExitApp

ChangePIN:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor
    
    ; Ask for current PIN
    lea dx, msgCurrentPIN
    call PrintString
    
    ; Read current PIN
    mov inputBuffer+1, 0
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h
    
    ; Validate current PIN
    lea si, inputBuffer+2
    lea di, correctPIN
    mov cx, 4
validateCurrentPIN:
    mov al, [si]
    cmp al, [di]
    jne wrongCurrentPIN
    inc si
    inc di
    loop validateCurrentPIN
    
    ; Current PIN is correct, ask for new PIN
askNewPIN:
    lea dx, msgNewPIN
    call PrintString
    
    ; Read new PIN
    mov inputBuffer+1, 0
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h
    
    ; Check if new PIN is 4 digits
    mov al, inputBuffer+1
    cmp al, 4
    jne invalidNewPIN
    
    ; Save new PIN temporarily
    lea si, inputBuffer+2
    lea di, numberBuffer+2
    mov cx, 4
saveTempPIN:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop saveTempPIN
    
    ; Ask to confirm new PIN
    lea dx, msgConfirmPIN
    call PrintString
    
    ; Read confirmation PIN
    mov inputBuffer+1, 0
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h
    
    ; Check if confirmation matches new PIN
    lea si, inputBuffer+2
    lea di, numberBuffer+2
    mov cx, 4
compareNewPINs:
    mov al, [si]
    cmp al, [di]
    jne pinMismatch
    inc si
    inc di
    loop compareNewPINs
    
    ; PINs match, update the correctPIN
    lea si, inputBuffer+2
    lea di, correctPIN
    mov cx, 4
updatePIN:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop updatePIN
    
    ; Success message
    lea dx, msgPINChanged
    call PrintString
    call HoldScreen
    jmp ATM_MENU
    
wrongCurrentPIN:
    lea dx, msgFail
    call PrintString
    call HoldScreen
    jmp ATM_MENU
    
invalidNewPIN:
    lea dx, msgInvalidInput
    call PrintString
    call HoldScreen
    jmp askNewPIN
    
pinMismatch:
    lea dx, msgPINMismatch
    call PrintString
    call HoldScreen
    jmp askNewPIN

ShowBalance:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    lea dx, msgBalance
    call PrintString
    mov ax, savingsBalance
    call PrintNumber

    lea dx, msgWallet
    call PrintString
    mov ax, walletBalance
    call PrintNumber

    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp ATM_MENU

Deposit:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    lea dx, msgAccountChoice
    call PrintString
    call ReadChar

    cmp al, '1'  ; Check if user selected "Savings"
    je DepositToSavings

    cmp al, '2'  ; Check if user selected "Wallet"
    je DepositToWallet

    cmp al, '3'  ; Check if user selected "Cancel"
    je DepositCancel

    ; Invalid choice handling
    lea dx, msgInvalidChoice
    call PrintString
    jmp Deposit  ; Prompt user to enter a valid option

DepositCancel:
    lea dx, msgCancel
    call PrintString
    call HoldScreen
    jmp ATM_MENU

DepositToSavings:
    lea dx, msgDeposit
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmount

    call ValidateNumericInput
    
    ; Record transaction
    push ax
    lea si, TRANS_DEPOSIT
    lea di, ACC_SAVINGS
    call RecordTransaction
    pop ax
    
    add savingsBalance, ax
    jmp DepositDone

DepositToWallet:
    lea dx, msgDeposit
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmount

    call ValidateNumericInput
    
    ; Record transaction
    push ax
    lea si, TRANS_DEPOSIT
    lea di, ACC_WALLET
    call RecordTransaction
    pop ax
    
    add walletBalance, ax

DepositDone:
    lea dx, msgDepositSuccess
    call PrintString
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp ATM_MENU

EmptyAmount:
    lea dx, msgEmptyAmount
    call PrintString
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp Deposit

ValidateNumericInput:
    ; Validate that the entered amount is numeric
    lea si, numberBuffer+2
    xor bx, bx ; Flag to check if the input is valid
    mov cx, 3  ; Total of 3 attempts
validateLoop:
    mov al, [si]
    cmp al, 13    ; Check for Enter key
    je doneValidate
    cmp al, '0'   
    jb invalidAmount
    cmp al, '9'
    ja invalidAmount
    inc si
    jmp validateLoop

invalidAmount:
    lea dx, msgInvalidAmount
    call PrintString
    dec cx
    cmp cx, 0
    je MaxAttemptsReached
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    
    ; Check which operation we're in and show appropriate message
    cmp currentOperation, 1
    jne checkWithdraw
    lea dx, msgDeposit
    jmp showPrompt
    
checkWithdraw:
    cmp currentOperation, 2
    jne checkTransfer
    lea dx, msgWithdraw
    jmp showPrompt
    
checkTransfer:
    lea dx, msgTransfer
    
showPrompt:
    call PrintString
    
    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h
    
    jmp validateLoop  ; Try validation again

MaxAttemptsReached:
    lea dx, msgMaxAttempts
    call PrintString
    call HoldScreen
    jmp ATM_MENU

doneValidate:
    ; Parse the number
    call ParseNumber
    ret

Withdraw:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    lea dx, msgAccountChoice
    call PrintString
    call ReadChar

    cmp al, '1'
    je WithdrawFromSavings
    cmp al, '2'
    je WithdrawFromWallet
    cmp al, '3'
    je WithdrawCancel
    jmp Withdraw

WithdrawCancel:
    lea dx, msgCancel
    call PrintString
    call HoldScreen
    jmp ATM_MENU

WithdrawFromSavings:
    lea dx, msgWithdraw
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmountWithdraw

    call ValidateNumericInput
    cmp ax, savingsBalance
    ja NotEnough
    
    ; Record transaction
    push ax
    lea si, TRANS_WITHDRAW
    lea di, ACC_SAVINGS
    call RecordTransaction
    pop ax
    
    sub savingsBalance, ax
    jmp WithdrawDone

WithdrawFromWallet:
    lea dx, msgWithdraw
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmountWithdraw

    call ValidateNumericInput
    cmp ax, walletBalance
    ja NotEnough
    
    ; Record transaction
    push ax
    lea si, TRANS_WITHDRAW
    lea di, ACC_WALLET
    call RecordTransaction
    pop ax
    
    sub walletBalance, ax
    jmp WithdrawDone

EmptyAmountWithdraw:
    lea dx, msgEmptyAmount
    call PrintString
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp Withdraw

NotEnough:
    lea dx, msgTooMuch
    call PrintString

WithdrawDone:
    lea dx, msgWithdrawSuccess
    call PrintString
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp ATM_MENU

Transfer:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    lea dx, msgTransferFrom
    call PrintString
    call ReadChar

    cmp al, '1'
    je TransferFromSavings
    cmp al, '2'
    je TransferFromWallet
    cmp al, '3'
    je TransferCancel
    jmp Transfer

TransferCancel:
    lea dx, msgCancel
    call PrintString
    call HoldScreen
    jmp ATM_MENU

TransferFromSavings:
    lea dx, msgTransfer
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmountTransfer

    call ValidateNumericInput
    cmp ax, savingsBalance
    ja TransferNotEnough
    
    ; Record transaction (from savings)
    push ax
    lea si, TRANS_TRANSFER
    lea di, ACC_SAVINGS
    call RecordTransaction
    pop ax
    
    ; Perform the transfer
    sub savingsBalance, ax
    add walletBalance, ax
    
    lea dx, msgTransferSuccess
    call PrintString
    jmp TransferDone

TransferFromWallet:
    lea dx, msgTransfer
    call PrintString

    lea dx, numberBuffer
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, numberBuffer+1
    cmp al, 0
    je EmptyAmountTransfer

    call ValidateNumericInput
    cmp ax, walletBalance
    ja TransferNotEnough
    
    ; Record transaction (from wallet)
    push ax
    lea si, TRANS_TRANSFER
    lea di, ACC_WALLET
    call RecordTransaction
    pop ax
    
    ; Perform the transfer
    sub walletBalance, ax
    add savingsBalance, ax
    
    lea dx, msgTransferSuccess
    call PrintString
    jmp TransferDone

EmptyAmountTransfer:
    lea dx, msgEmptyAmount
    call PrintString
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp Transfer

TransferNotEnough:
    lea dx, msgTooMuch
    call PrintString

TransferDone:
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp ATM_MENU

ShowHistory:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor
    
    lea dx, msgHistory
    call PrintString
    
    cmp transactionCount, 0
    je NoHistory
    
    ; Display all transactions
    lea si, transactions
    xor bl, bl  ; Clear BL to use as counter
    
DisplayLoop:
    cmp bl, transactionCount
    jae HistoryDone
    
    ; Display transaction type
    mov cx, 10
    mov ah, 02h
DisplayTypeLoop:
    mov dl, [si]
    cmp dl, '$'
    je SkipTypeRest
    int 21h
    inc si
    loop DisplayTypeLoop
    jmp TypeDone
    
SkipTypeRest:
    add si, cx  ; Skip remaining bytes in this field
    
TypeDone:
    ; Print spaces
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h
    
    ; Display account type
    mov cx, 10
    mov ah, 02h
DisplayAccountLoop:
    mov dl, [si]
    cmp dl, '$'
    je SkipAccountRest
    int 21h
    inc si
    loop DisplayAccountLoop
    jmp AccountDone
    
SkipAccountRest:
    add si, cx  ; Skip remaining bytes in this field
    
AccountDone:
    ; Print spaces
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h
    
    ; Print amount
    mov ax, [si]  ; Get amount from the transaction record
    call PrintNumber
    
    ; Move to next line
    call NewLine
    
    add si, 10  ; Skip to next transaction record (10 remaining bytes)
    inc bl      ; Increment transaction counter
    jmp DisplayLoop
    
NoHistory:
    lea dx, msgNoHistory
    call PrintString

HistoryDone:
    lea dx, msgAnyKey
    call PrintString
    call HoldScreen
    jmp ATM_MENU

PIN_LOCKED:
    lea dx, msgLocked
    call PrintString
    call HoldScreen
    jmp WELCOME_START

ExitApp:
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Set text color to orange after clearing screen
    call SetOrangeTextColor

    lea dx, msgExit
    call PrintString
    call HoldScreen
    mov ah, 4Ch
    int 21h
main endp

; Helper procedure to print a transaction field
; Input: SI = pointer to field, CX = field length
PrintTransactionField proc
    push ax
    push dx
    push cx
    
PrintFieldLoop:
    mov dl, [si]
    cmp dl, '$'  ; Check for end of string
    je FieldPadding
    mov ah, 02h
    int 21h
    inc si
    loop PrintFieldLoop
    jmp FieldDone
    
FieldPadding:
    ; Skip past the $ and any remaining characters in this field
    add si, cx
    
FieldDone:
    ; Print space separator
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    pop cx
    pop dx
    pop ax
    ret
PrintTransactionField endp

; Helper procedure to print a new line
NewLine proc
    push ax
    push dx
    
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    
    pop dx
    pop ax
    ret
NewLine endp

; Records a transaction
; Input: SI = pointer to transaction type string
;        DI = pointer to account type string
;        AX = amount
RecordTransaction proc
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Check if we have space for more transactions
    cmp transactionCount, MAX_TRANSACTIONS
    jae TransactionFull
    
    ; Calculate position in transactions array
    xor bx, bx
    mov bl, transactionCount
    mov ax, 30
    mul bx
    
    lea di, transactions
    add di, ax
    
    ; Copy transaction type (10 bytes)
    mov cx, 10
CopyTypeLoop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    cmp al, '$'
    je PadTypeField
    loop CopyTypeLoop
    jmp TypeCopyDone
    
PadTypeField:
    dec cx
    jz TypeCopyDone
    mov byte ptr [di], ' '
    inc di
    loop PadTypeField
    
TypeCopyDone:
    ; Save SI and restore DI for account type
    push si
    mov si, [bp-12]  ; Get original DI value (account type pointer)
    
    ; Copy account type (10 bytes)
    mov cx, 10
CopyAccountLoop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    cmp al, '$'
    je PadAccountField
    loop CopyAccountLoop
    jmp AccountCopyDone
    
PadAccountField:
    dec cx
    jz AccountCopyDone
    mov byte ptr [di], ' '
    inc di
    loop PadAccountField
    
AccountCopyDone:
    ; Restore SI
    pop si
    
    ; Store amount (word at offset 20)
    mov ax, [bp+4] ; Get amount from stack
    mov [di], ax
    
    ; Increment transaction count
    inc transactionCount
    
TransactionFull:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
RecordTransaction endp

AnimatedPrint proc
.nextChar:
    mov al, [si]
    cmp al, 0
    je .done_animated
    mov dl, al
    mov ah, 02h
    int 21h
    call Delay
    inc si
    jmp .nextChar
.done_animated:
    ret
AnimatedPrint endp

PrintString proc
    mov ah, 09h
    int 21h
    ret
PrintString endp

ReadChar proc
    mov ah, 01h
    int 21h
    ret
ReadChar endp

Delay proc
    mov cx, 0FFFFh
.delayLoop:
    nop
    loop .delayLoop
    ret
Delay endp

ShortDelay proc
    mov cx, 0FFFh
.shortLoop:
    nop
    loop .shortLoop
    ret
ShortDelay endp

HoldScreen proc
    mov ah, 07h
    int 21h
    ret
HoldScreen endp

ParseNumber proc
    lea si, numberBuffer+2
    xor ax, ax
    xor bx, bx
parseLoop:
    mov bl, [si]
    cmp bl, 13
    je doneParse
    cmp bl, '0'
    jb doneParse
    cmp bl, '9'
    ja doneParse
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    inc si
    jmp parseLoop

doneParse:
    ret
ParseNumber endp

PrintNumber proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
.nextDigit:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jnz .nextDigit
.printLoop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop .printLoop
    
    ; Print currency symbol
    mov dl, '$'
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber endp

; New procedure to set text color to orange
SetOrangeTextColor proc
    push ax
    push bx
    
    ; Set foreground color only to orange, keep background black
    mov ah, 06h   ; Scroll up function (0 lines = clear)
    mov al, 0     ; Clear entire window
    mov bh, ORANGE_TEXT  ; Orange on black (low 4 bits = background, high 4 bits = foreground)
    mov ch, 0     ; Upper left row
    mov cl, 0     ; Upper left column
    mov dh, 24    ; Lower right row
    mov dl, 79    ; Lower right column
    int 10h
    
    pop bx
    pop ax
    ret
SetOrangeTextColor endp

END main