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
	call makeDaisy
	call displayCube
	call solveWEdges
	
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
	call crlf

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

mov esi, OFFSET sides + 9 * o; set esi to point to the 1st element in blue array
mov edi, OFFSET sides + 9 * g; set edi to point to the 1st element in red array
mov ecx, 3;

wSwap:
push edi
	
mov al, [esi]; swap the elements for blue, red, green, and orange
mov bl, [edi]
mov [edi], al
sub edi, 9
mov al, [edi]
mov [edi], bl
sub edi, 9
mov bl, [edi]
mov [edi], al
sub edi, 9
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

mov ecx, 3
mov ebx, 0
mov edx, 0
bMvSqr:
mov esi, OFFSET sides + 9 * r
add esi, edx

mov edi, OFFSET sides + 9 * w + 8
sub edi, ebx

mov al, [esi]
mov ah, [edi]
mov [edi], al

mov edi, OFFSET sides + 9*o + 8
sub edi, edx
mov al, [edi]
mov [edi], ah

mov edi, OFFSET sides  + 9*y + 6
add edi, ebx
mov ah, [edi]
mov [edi], al
mov [esi], ah 
add edx, 3
inc ebx
loop bMvSqr

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

mov ecx, 3
mov ebx, 0
mov edx, 0
gMvSqr:
mov esi, OFFSET sides + 9 * r + 2

add esi, edx
mov edi, OFFSET sides + 9 * y
add edi, ebx

mov al, [esi]
mov ah, [edi]
mov [edi], al

mov edi, OFFSET sides + 9*o + 6
sub edi, edx
mov al, [edi]
mov [edi], ah

mov edi, OFFSET sides  + 9*w + 2
sub edi, ebx
mov ah, [edi]
mov [edi], al
mov [esi], ah 
add edx, 3
inc ebx
loop gMvSqr

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

makeDaisy proc ;go through each edge to finish daisy
	mustcheckfour:
		mov esi, OFFSET sides + 9*y
		cmp byte ptr [esi+1], w
		jne fW
		cmp byte ptr [esi+3], w
		jne fW
		cmp byte ptr [esi+5], w
		jne fW
		cmp byte ptr [esi+7], w
		jne fW
		je continue
	fW:
		call findW
		jmp mustcheckfour
	continue:
	ret
makeDaisy ENDP

findW proc ;find a white edge
	whit: ;assume on white face
		mov esi, OFFSET sides + 9*w
		mov al, 1
		cmp byte ptr [esi+1], w
		je Wmove
		mov al, 3
		cmp byte ptr [esi+3], w
		je Wmove
		mov al, 5
		cmp byte ptr [esi+5], w
		je Wmove
		mov al, 7
		cmp byte ptr [esi+7], w
		je Wmove
	blu:
		mov esi, OFFSET sides + 9*b
		mov al, 1
		cmp byte ptr [esi+1], w
		je Bmove
		mov al, 3
		cmp byte ptr [esi+3], w
		je Bmove
		mov al, 5
		cmp byte ptr [esi+5], w
		je Bmove
		mov al, 7
		cmp byte ptr [esi+7], w
		je Bmove
	rd:
		mov esi, OFFSET sides + 9*r
		mov al, 1
		cmp byte ptr [esi+1], w
		je Rmove
		mov al, 3
		cmp byte ptr [esi+3], w
		je Rmove
		mov al, 5
		cmp byte ptr [esi+5], w
		je Rmove
		mov al, 7
		cmp byte ptr [esi+7], w
		je Rmove
	grn:
		mov esi, OFFSET sides + 9*g
		mov al, 1
		cmp byte ptr [esi+1], w
		je Gmove
		mov al, 3
		cmp byte ptr [esi+3], w
		je Gmove
		mov al, 5
		cmp byte ptr [esi+5], w
		je Gmove
		mov al, 7
		cmp byte ptr [esi+7], w
		je Gmove
	ornge:
		mov esi, OFFSET sides + 9*o
		mov al, 1
		cmp byte ptr [esi+1], w
		je Omove
		mov al, 3
		cmp byte ptr [esi+3], w
		je Omove
		mov al, 5
		cmp byte ptr [esi+5], w
		je Omove
		mov al, 7
		cmp byte ptr [esi+7], w
		je Omove
	Wmove:
		call Wmove
		jmp continue
	Bmove:
		call Bmove
		jmp continue
	Rmove:
		call Rmove
		jmp continue
	Gmove:
		call Gmove
		jmp continue
	Omove:
		call Omove
		jmp continue
	continue:
	ret
findW ENDP

Wmove proc
	mov esi, OFFSET sides + 9*y
	initialstep:
		cmp al, 1
		je solveB
		cmp al, 5
		je solveS5
		cmp al, 3
		je solveS3
		cmp al, 7
		je solveT
	solveT:
		cmp byte ptr [esi+7], w
		je rotateY
		call turnB
		call turnB
		jmp continue
	solveS5:
		cmp byte ptr [esi+5], w
		je rotateY
		call turnR
		call turnR
		jmp continue
	solveS3:
		cmp byte ptr [esi+3], w
		je rotateY
		call turnO
		call turnO
		jmp continue
	solveB:
		cmp byte ptr [esi+1], w
		je rotateY
		call turnG
		call turnG
		jmp continue
	rotateY:
		call turnY
		jmp initialstep
	continue:
	ret
Wmove ENDP

Bmove proc
	mov esi, OFFSET sides + 9*y
	cmp al, 1
	je solveT
	cmp al, 3
	je solveS3
	cmp al, 5
	je solveS5
	cmp al, 7
	je solveB
	solveT:
		call turnB
		jmp solveS5
	solveS3:
		cmpY:
			cmp byte ptr [esi+3], w
			je rtY
			call turnO
			call turnO
			call turnO
			jmp continue
		rtY:
			call turnY
			jmp cmpY
	solveS5:
		compY:
			cmp byte ptr [esi+5], w
			je rotY
			call turnR
			jmp continue
		rotY:
			call turnY
			jmp compY 
	solveB:
		checkYs:
			cmp byte ptr [esi+7], w
			je rotatY
			call turnB
			jmp solveS3
		rotatY:
			call turnY
			jmp checkYs
	continue:
	ret
Bmove ENDP


Rmove proc
mov esi, OFFSET sides + 9*y
	cmp al, 1
	je solveT
	cmp al, 3
	je solveS3
	cmp al, 5
	je solveS5
	cmp al, 7
	je solveB
	solveT:
		call turnR
		jmp solveS5
	solveS3:
		cmpY:
			cmp byte ptr [esi+3], w
			je rtY
			call turnB
			call turnB
			call turnB
			jmp continue
		rtY:
			call turnY
			jmp cmpY
	solveS5:
		compY:
			cmp byte ptr [esi+5], w
			je rotY
			call turnG
			jmp continue
		rotY:
			call turnY
			jmp compY 
	solveB:
		checkYs:
			cmp byte ptr [esi+7], w
			je rotatY
			call turnR
			jmp solveS3
		rotatY:
			call turnY
			jmp checkYs
	continue:
	ret
Rmove ENDP

Gmove proc
mov esi, OFFSET sides + 9*y
	cmp al, 1
	je solveT
	cmp al, 3
	je solveS3
	cmp al, 5
	je solveS5
	cmp al, 7
	je solveB
	solveT:
		call turnG
		jmp solveS5
	solveS3:
		cmpY:
			cmp byte ptr [esi+3], w
			je rtY
			call turnR
			call turnR
			call turnR
			jmp continue
		rtY:
			call turnY
			jmp cmpY
	solveS5:
		compY:
			cmp byte ptr [esi+5], w
			je rotY
			call turnO
			jmp continue
		rotY:
			call turnY
			jmp compY 
	solveB:
		checkYs:
			cmp byte ptr [esi+7], w
			je rotatY
			call turnG
			jmp solveS3
		rotatY:
			call turnY
			jmp checkYs
	continue:
	ret
Gmove ENDP

Omove proc
mov esi, OFFSET sides + 9*y
	cmp al, 1
	je solveT
	cmp al, 3
	je solveS3
	cmp al, 5
	je solveS5
	cmp al, 7
	je solveB
	solveT:
		call turnO
		jmp solveS5
	solveS3:
		cmpY:
			cmp byte ptr [esi+3], w
			je rtY
			call turnG
			call turnG
			call turnG
			jmp continue
		rtY:
			call turnY
			jmp cmpY
	solveS5:
		compY:
			cmp byte ptr [esi+5], w
			je rotY
			call turnB
			jmp continue
		rotY:
			call turnY
			jmp compY 
	solveB:
		checkYs:
			cmp byte ptr [esi+7], w
			je rotatY
			call turnO
			jmp solveS3
		rotatY:
			call turnY
			jmp checkYs
	continue:
	ret
Omove ENDP
; determine colors on side of desired color, turn both of those
turnMiddle PROC

turnMiddle ENDP
END main