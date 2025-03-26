TITLE Project Six     (Proj6_Strandga.asm)

; Author: Gannon Strand
; Last Modified: 03/06/25
; OSU email address: strandga@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 03/16/25
; Description: This program will read a file as entered by the user and reverse the order of temperatures stored within that file.
;			   It will then display those temps as integers before saying farwell.

INCLUDE Irvine32.inc

; (insert macro definitions here)

; Macro to display header/prompt, get value from user(and stores it), ensures user input is not bigger then count, and provides a number of bytes read.
; preconditions: prompt, error, userval, count, and bytesread defined.
; postconditions: userval is less then or equal to 30 bytes or it will end the program.
; registers changed: None
; recieves: prompt, error, userval, count, bytesread
; returns: userval, bytesread
mGetString MACRO prompt:REQ, error:REQ, userval:REQ, count:REQ, bytesread:REQ
	PUSH	EDX
	PUSH	EAX
	PUSH	ECX
	PUSH	EBX

_start:
	MOV		EBX, count
	CALL	Crlf
	mDisplayString prompt
; Pre conditions of ReadString ECX contains the buffer size, EDX is the address of the buffer
	MOV		EDX, OFFSET userval
	DEC		EBX
	MOV		ECX, EBX
	INC		EBX
	CALL	ReadString
; Post conditions of ReadString EAX contains number of bytes read from terminal, EDX has address of user entered string
	MOV		bytesread, EAX

	SUB		EBX, 3
	CMP		bytesread, EBX					; checks if user val is less then or equal to 30 characters
	JG		_error
	JMP		_end

_error:
	mDisplayString error					; if string is over 30 characters displays an error
	CALL	Crlf
	Invoke ExitProcess,0					; exit to operating system

_end:
	POP		EAX
	POP		EBX
	POP		ECX
	POP		EDX
ENDM

; Macro to display a string.
; preconditions: string is deined.
; postconditions: None
; registers changed: None
; recieves: string
; returns: Printed String
mDisplayString MACRO string:REQ
	PUSH	EDX

	MOV		EDX, OFFSET string
	CALL	WriteString

	POP		EDX
ENDM

; Macro to display a character.
; preconditions: char is defined.
; postconditions: None
; registers changed: None
; recieves: char
; returns: Printed Character
mDisplayChar MACRO char:REQ
	PUSH	EAX

	MOV		AL, char
	CALL	WriteChar

	POP		EAX
ENDM

; (insert constant definitions here)

	count			= 33					; Constant for max number of characters allowed (which is subtracted by 3 earlier.)
	TEMPS_PER_DAY	= 24
	DELIMITER		= ','
	BUFFERSIZE		= TEMPS_PER_DAY * 5		; Should have enough room for the buffer, leaves room for worst case all negative three digit numbers with deliminator.

.data

; (insert variable definitions here)

	header		BYTE	"Welcome to Intern Fixinator by Gannon Strand", 0
	instruct	BYTE	"This program will open a file name you enter (under 31 characters) that is ASCII-formatted, and I will reverse that order and print out the corrected temps!", 0
	prompt		BYTE	"Please enter the name of the file: ", 0
	error		BYTE	"String entered is too large!", 0
	error2		BYTE	"File not found", 0
	farwell		BYTE	"Thanks for using Intern Fixinator! Bye! :)", 0
	filebuffer	BYTE	BUFFERSIZE DUP(?)
	userval		BYTE	count DUP(0)		; stores file name that the user enters.
	bytesread	DWORD	?					; stores number of bytes read in userval.
	tempArray	SDWORD	TEMPS_PER_DAY DUP(?)

.code
main PROC

; (insert executable instructions here)

; Deals with displaying header instructions and getting user entered file. 
	PUSH	EDX
	PUSH	EAX
	PUSH	ECX

	mDisplayString header
	CALL	Crlf
	mDisplayString instruct
	mGetString  prompt, error, userval, count, bytesread

	MOV		EDX, OFFSET userval
; Pre conditions EDX contains name of file. 
	CALL	OpenInputFile
; Post conditions EAX contains file handle or INVALID_HANDLE_VALUE

	CMP		EAX, INVALID_HANDLE_VALUE		; Checks EAX for INVALID_HANDLE_VALUE indicating a file could not be opened 
	JE		_file_error
	JMP		_continue

_file_error:
	mDisplayString	error2					; If file is not found prints error
	Invoke ExitProcess,0					; exit to operating system

_continue:
; Deals with Reading Data from the file and moving that to the file buffer before closing the file. 
	MOV		EDX, OFFSET filebuffer
	MOV		ECX, BUFFERSIZE
	CALL	ReadFromFile

; Pre conditions EAX contains file handle
	CALL	CloseFile

; Calls the two main functions and pushes values/arrays/buffers
	PUSH	OFFSET fileBuffer
	PUSH	OFFSET TEMPS_PER_DAY
	PUSH	OFFSET DELIMITER
	PUSH	OFFSET tempArray
	CALL	ParseTempsFromString

	PUSH	OFFSET tempArray
	PUSH	OFFSET DELIMITER
	PUSH	OFFSET TEMPS_PER_DAY
	CALL	WriteTempsReverse

	CALL	Crlf
	mDisplayString farwell					; Goodbye Message Printed

	PUSH	EDX
	PUSH	EAX
	PUSH	ECX
	Invoke ExitProcess,0					; exit to operating system
main ENDP

; (insert additional procedures here)

; Procedure to parse temperatures in file convert it to numeric value and save.
; preconditions: fileBuffer defined and has contents, TEMPS_PER_DAY, DELIMITER, and tempArray defined.
; postconditions: None
; registers changed: None
; recieves: [EBP + 8] = tempArray, [EBP + 12] = DELIMITER, [EBP + 16] = TEMPS_PER_DAY, [EBP + 20] = fileBuffer
; returns: tempArray
ParseTempsFromString PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	EDI
	PUSH	ESI

	MOV		EDI, [EBP + 8]
	MOV		DL, [EBP + 12]
	MOV		CL, [EBP + 16]
	MOV		ESI, [EBP + 20]

_char:
	LODSB
	CMP		CL, 0
	JE		_finish
	CMP		AL, DL							; Skips the character if it is the deliminator
	JE		_char
	CMP		AL, '-'							; Checks if it is a negative number
	JE		_negative
	SUB		AL, '0'							; Converts to a numeric value
	MOV		BL, AL
	JMP		_positive

_negative:
	LODSB
	SUB		AL, '0'
	MOV		BL, AL
	JMP		_negative2						; _negative2 is to ensure it jumps properly to _storenegnumber to properly negate the number.
	
	
_positive:
	LODSB
	CMP		AL, DL							; if it hits the deliminator jumps to store the value
	JE		_storeposnumber

	SUB		AL, '0'
	PUSH	EDX
	MOV		DL, AL
	MOV		AL, BL
	MOV		BL, 10							; To deal with numbers such as 327, multiplying the first nnumber by 10 to get 30 and adding 2 and repating to get 327 in the end.
	MUL		BL
	MOV		BL, AL
	MOV		AL, DL
	POP		EDX	
	ADD		AL, BL
	MOV		BL, AL
	JMP		_positive

_negative2:
	LODSB
	CMP		AL, DL
	JE		_storenegnumber

	SUB		AL, '0'
	PUSH	EDX
	MOV		DL, AL
	MOV		AL, BL
	MOV		BL, 10
	MUL		BL
	MOV		BL, AL
	MOV		AL, DL
	POP		EDX	

	ADD		AL, BL
	MOV		BL, AL
	JMP		_negative2

_storeposnumber:
	MOV		[EDI], BL
	ADD		EDI, 4
	DEC		CL
	JMP		_char

_storenegnumber:
	MOV		[EDI], BL
	MOV		EBX, [EDI]
	NEG		EBX
	MOV		[EDI], EBX						; To properly negate moves it into EBX negates it and then moves it back.
	ADD		EDI, 4
	DEC		CL
	JMP		_char

_finish:
	POP		EAX
	POP		EBX
	POP		ECX
	POP		EDX
	POP		EDI
	POP		ESI
	POP		EBP
ret 16
ParseTempsFromString ENDP

; Procedure to display integers in reverse order of the original file.
; preconditions: TEMPS_PER_DAY, DELIMITER, tempArray is defined
; postconditions: None
; registers changed: None
; recieves: [EBP + 8] = TEMPS_PER_DAY, [EBP + 12] = DELIMITER,  [EBP + 16] = tempArray
; returns: Printed reversed tempArray
WriteTempsReverse PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EDX
	PUSH	EDI
	PUSH	ECX
	PUSH	EBX
	PUSH	EAX

	MOV		ECX, [EBP + 8]
	MOV		EDI, [EBP + 16]
	
	MOV		EAX, ECX
	MOV		EBX, 4
	MUL		EBX								; Multiplies it temps per day by 4 subtracted by 4 to get to the end of the list to start rather than the start.

	ADD		EDI, EAX
	SUB		EDI, 4

_loop:
	PUSH	EAX
	MOV		EAX, [EDI]
	CALL	WriteInt
	mDisplayChar [EBP + 12]					; Prints the deliminator using macro.
	SUB		EDI, 4
	POP		EAX
	LOOP	_loop

	POP		EAX
	POP		EDX
	POP		EDI
	POP		ECX
	POP		EBX
	POP		EBP
ret 12
WriteTempsReverse ENDP

END main
