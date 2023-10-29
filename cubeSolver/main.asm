.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD 

INCLUDE Irvine32.inc

.data
;outFile
filename byte "moves.txt"
filehandle dword ?
MOVESIZE = 3
front byte "F", 13, 10, 0
back byte "B", 13, 10, 0
right byte "R", 13, 10, 0
left byte "L", 13, 10, 0
up byte "U", 13, 10, 0
down byte "D", 13, 10, 0

;define colors
w equ 0
y equ 1
b equ 2
r equ 3
g equ 4
o equ 5

;Define side arrays, to simplify, side1 is top, side2 is bottom
;Listed in anticlockwise order: side3, side4, side5, side6 
;Where 3 and 5 oppose each other and 4 and 6 oppose each other 
sides byte 9 DUP(w); white opposes yellow
	  byte 9 DUP(y); yellow opposes white
	  byte 9 DUP(b); blue opposes green
	  byte 9 DUP(r); red opposes orange
	  byte 9 DUP(g); green opposes blue
	  byte 9 DUP(o); orange opposes red

.code
main PROC
	;call initCube either shuffle solved cube or generate solvable cube
	call initCube
	
	call turnO

	call displayCube
	
	mov eax, filehandle
	call CloseFile
	INVOKE ExitProcess, 0
main ENDP

initCube proc 
	push edx
	push eax
	mov edx, OFFSET filename
	call CreateOutputFile
	mov filehandle, eax
	pop eax
	pop edx
	ret
initCube ENDP

displayCube proc
	push esi
	push ecx
	mov esi, OFFSET sides + 9 * y
	call printSide
	mov ecx, 4
	mov esi, OFFSET sides + 9 * b
	call crlf
	printSides:
		call printSide
		call crlf
		add esi, 9
	loop printSides
	mov esi, OFFSET sides
	call printSide

	pop ecx
	pop esi
ret
displayCube ENDP

printSide PROC
	push esi
	push eax
	push ebx
	push ecx
	mov ebx, 3
	pSide:
	mov ecx, 3
		printRow:
		mov al, [esi]
		push ebx
		push eax
		cmp al, w; set appropriate color for text
		je sW
		cmp al, y
		je sY
		cmp al, b
		je sB
		cmp al, r
		je sR
		cmp al, g
		je sG
		cmp al, o
		je sO

		sW:
		mov eax, white
		jmp aS
		sY:
		mov eax, yellow
		jmp aS
		sB:
		mov eax, blue
		jmp aS
		sR:
		mov eax, red
		jmp aS
		sG:
		mov eax, green
		jmp aS
		sO:
		mov eax, lightRed
		jmp aS

		aS:
		call SetTextColor; set text color, write value, and delimiter
		pop eax
		mov ebx, 1
		call writeHexB
		pop ebx
		mov al, '|'
		call writeChar
		inc esi
		loop printRow
	call crlf
	dec ebx
	jnz pSide
	pop ecx
	pop ebx
	pop eax
	pop esi
	ret
printSide ENDP

; clockwise turn 
; Parameters - EDX = side to write to file
turnClock PROC
	push esi
	push eax
	push ebx

	;write move to file
	push eax
	push ecx
	mov eax, filehandle
	mov ecx, MOVESIZE
	call WriteToFile
	pop ecx
	pop eax

	mov al, [esi]; move corners to new locations 0->2, 2->8, 8->6, 6->0
	mov bl, [esi + 2]
	mov [esi + 2], al
	mov al, [esi + 8]
	mov [esi + 8], bl
	mov bl, [esi + 6]
	mov [esi + 6], al
	mov [esi], bl

	mov al, [esi + 1]; move edges to new locations 1->5, 5->7, 7->3, 3->1
	mov bl, [esi + 5]
	mov [esi + 5], al
	mov al, [esi + 7]
	mov [esi + 7], bl
	mov bl, [esi + 3]
	mov [esi + 3], al
	mov [esi+1], bl

	mov al, [esi + 5]
	pop ebx
	pop eax
	pop esi
	ret
	
turnClock ENDP

turnW PROC
push esi
push edi
push eax
push ebx
push ecx
push edx

mov edx, OFFSET down
mov esi, OFFSET sides
call turnClock

mov esi, OFFSET sides + 9 * b + 6; set esi to point to the 7th element in blue array
mov edi, OFFSET sides + 9 * r + 6; set edi to point to the 7th element in red array

mov ecx, 3;
wSwap:
push edi
	
mov al, [esi]; swap the elements for blue, red, green, and orange
mov bl, [edi]
mov [edi], al
add edi, 9
mov al, [edi]
mov [edi], bl
add edi, 9
mov bl, [edi]
mov [edi], al
add edi, 9
mov [esi], bl
	
inc esi
pop edi
inc edi
loop wSwap
pop edx
pop ecx
pop ebx
pop eax
pop edi
pop esi
ret
turnW ENDP

turnY PROC
push esi
push edi
push eax
push ebx
push ecx
push edx

mov edx, OFFSET up
mov esi, OFFSET sides + 9*y
call turnClock

mov esi, OFFSET sides + 9 * b; set esi to point to the 1st element in blue array
mov edi, OFFSET sides + 9 * r; set edi to point to the 1st element in red array
mov ecx, 3;

wSwap:
push edi
	
mov al, [esi]; swap the elements for blue, red, green, and orange
mov bl, [edi]
mov [edi], al
add edi, 9
mov al, [edi]
mov [edi], bl
add edi, 9
mov bl, [edi]
mov [edi], al
add edi, 9
mov [esi], bl
	
inc esi
pop edi
inc edi
loop wSwap
pop edx
pop ecx
pop ebx
pop eax
pop edi
pop esi
ret
turnY ENDP

turnB PROC
push esi
push edi
push eax
push ebx
push ecx
push edx

mov edx, OFFSET front
mov esi, OFFSET sides + 9*b
call turnClock

mov esi, OFFSET sides + 9 * r; use pointer for orange / red
mov edi, OFFSET sides + 6; use pointer for white/yellow
mov ecx, 3
bmvSqr:
mov  al, [esi]
mov  bl, [edi]
mov [edi], al
mov al, [esi + 9 * (o-r) + 2]
mov [esi + 9 * (o-r) + 2], bl
mov bl, [edi + 9 * (y-w)]
mov [edi + 9 * (y-w)], al
mov [esi], bl
add esi, 3
inc edi
loop bmvSqr

pop edx
pop ecx
pop ebx
pop eax
pop edi
pop esi
ret
turnB ENDP

turnR PROC
push esi
push edi
push eax
push ebx
push edx

mov edx, OFFSET right
mov esi, OFFSET sides + 9*r
call turnClock

mov esi, OFFSET sides + 9*y + 2;move first square
mov edi, OFFSET sides + 9*g + 6
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides + 8]
mov [OFFSET sides + 8], bl
mov bl, [OFFSET sides + 9*b + 2]
mov [OFFSET sides + 9*b + 2], al
mov [esi], bl

add esi, 3
sub edi, 3
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides + 5]
mov [OFFSET sides + 5], bl
mov bl, [OFFSET sides + 9*b + 5]
mov [OFFSET sides + 9*b + 5], al
mov [esi], bl

add esi, 3
sub edi, 3
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides + 2]
mov [OFFSET sides + 2], bl
mov bl, [OFFSET sides + 9*b + 8]
mov [OFFSET sides + 9*b + 8], al
mov [esi], bl

pop edx
pop ebx
pop eax
pop edi
pop esi
ret
turnR ENDP

turnG PROC
push esi
push edi
push eax
push ebx
push ecx
push edx

mov edx, OFFSET back
mov esi, OFFSET sides + 9*g
call turnClock

mov esi, OFFSET sides + 9 * r + 2
mov edi, OFFSET sides
mov ecx, 3
gmvSqr:
mov  al, [esi]
mov  bl, [edi]
mov [edi], al
mov al, [esi + 9 * (o-r) - 2]
mov [esi + 9 * (o-r) - 2], bl
mov bl, [edi + 9 * (y-w)]
mov [edi + 9 * (y-w)], al
mov [esi], bl
add esi, 3
inc edi
loop gmvSqr

pop edx
pop ecx
pop ebx
pop eax
pop edi
pop esi
ret
turnG ENDP

turnO PROC
push esi
push edi
push eax
push ebx
push edx

mov edx, OFFSET left
mov esi, OFFSET sides + 9*o
call turnClock

mov esi, OFFSET sides + 9*y;move first square
mov edi, OFFSET sides + 9*b
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides + 6]
mov [OFFSET sides + 6], bl
mov bl, [OFFSET sides + 9*g + 8]
mov [OFFSET sides + 9*g + 8], al
mov [esi], bl

add esi, 3
add edi, 3
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides + 3]
mov [OFFSET sides + 3], bl
mov bl, [OFFSET sides + 9*g + 5]
mov [OFFSET sides + 9*g + 5], al
mov [esi], bl

add esi, 3
add edi, 3
mov al, [esi]
mov bl, [edi]
mov [edi], al
mov al, [OFFSET sides]
mov [OFFSET sides], bl
mov bl, [OFFSET sides + 9*g + 2]
mov [OFFSET sides + 9*g + 2], al
mov [esi], bl

pop edx
pop ebx
pop eax
pop edi
pop esi
ret
turnO ENDP

; determine colors on side of desired color, turn both of those
turnMiddle PROC

turnMiddle ENDP
END main