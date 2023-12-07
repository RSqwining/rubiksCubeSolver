.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD 

INCLUDE Irvine32.inc

.data
;outFile
filename byte "moves.txt"
filehandle dword ?
MOVESIZE = 2
front byte "F "
back byte "B "
right byte "R "
left byte "L "
up byte "U "
down byte "D "

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

	;call turnW
	;call turnY
	;call turnY
	;call turnG
	;call turnR
	;call turnG
	;call turnB
	;call turnB
	;call turnB
	;call turnR
	;call turnR
	;call turnO
	;call turnO
	call displayCube
	call makeDaisy
	call displayCube
	call solveWEdges
	call displayCube
	call makeFLayer
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

mov al, [esi]; move corners to new locations 0->6, 6->8, 8->2, 2->0
mov bl, [esi + 6]
mov [esi + 6], al
mov al, [esi + 8]
mov [esi + 8], bl
mov bl, [esi + 2]
mov [esi + 2], al
mov [esi], bl

mov al, [esi + 5]; move edges to new locations 5->1, 1->3,  3->7, 7->5,
mov bl, [esi + 1]
mov [esi + 1], al
mov al, [esi + 3]
mov [esi + 3], bl
mov bl, [esi + 7]
mov [esi + 7], al
mov [esi+5], bl

mov al, [esi + 5]
pop ebx
pop eax
pop esi

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
			cmp byte ptr [esi+7], w
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
			cmp byte ptr [esi+1], w
			je rotY
			call turnG
			jmp continue
		rotY:
			call turnY
			jmp compY 
	solveB:
		checkYs:
			cmp byte ptr [esi+5], w
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

solveWEdges PROC
	push esi
	push ebx

	mov ebx, 0
	mov esi, OFFSET sides + 9*y

	checkForW:
	call checkWAndGCenter
	call checkWAndOCenter
	call checkWAndRCenter
	call checkWAndBCenter
	cmp ebx, 4
	je wEdgeSolved
	call turnY
	call displayCube
	jmp checkForW

	wEdgeSolved:
	pop ebx
	pop esi
	ret
solveWEdges ENDP

; procs to check white edges, increments ebx if edge was found and processed
checkWAndGCenter PROC
	push esi
	push eax

	cmp byte ptr [esi + 1], w
	jne done

	mov esi, OFFSET sides + 9*g
	mov al, [esi + 1]
	cmp al, [esi + 4]
	jne done
	call turnG
	call turnG
	inc ebx

	done:
	pop eax
	pop esi
	ret
checkWAndGCenter ENDP

checkWAndOCenter PROC
	push esi
	push eax

	cmp byte ptr [esi + 3], w
	jne done

	mov esi, OFFSET sides + 9*o
	mov al, [esi + 1]
	cmp al, [esi + 4]
	jne done

	call turnO
	call turnO
	inc ebx

	done:
	pop eax
	pop esi
	ret
checkWAndOCenter ENDP

checkWAndRCenter PROC
	push esi
	push eax
	cmp byte ptr [esi + 5], w
	jne done

	mov esi, OFFSET sides + 9*r
	mov al, [esi + 1]
	cmp al, [esi + 4]
	jne done
	call turnR
	call turnR
	inc ebx

	done:
	pop eax
	pop esi
	ret
checkWAndRCenter ENDP

checkWAndBCenter PROC
	push esi
	push eax
	cmp byte ptr [esi + 7], w
	jne done

	mov esi, OFFSET sides + 9*b
	mov al, [esi + 1]
	cmp al, [esi + 4]
	jne done
	call turnB
	call turnB
	inc ebx

	done:
	pop eax
	pop esi
	ret
checkWAndBCenter ENDP

makeFLayer proc
    mustsolvefour:
        call fixBRW
        call fixRGW
        call fixGOW
        call fixOBW
        ret
makeFLayer ENDP

fixBRW proc
    Tcorner1:
        checkWT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], w
            je checkBT1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], w
            je checkBT1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], w
            je checkBT1
            jmp Tcorner3
        checkBT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], b
            je checkRT1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], b
            je checkRT1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], b
            je checkRT1
            jmp Tcorner3
        checkRT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], r
            je moveBRW_T1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], r
            je moveBRW_T1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], r
            je moveBRW_T1
            jmp Tcorner3
    Tcorner3:
        checkWT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], w
            je checkBT3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], w
            je checkBT3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], w
            je checkBT3
            jmp Tcorner7
        checkBT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], b
            je checkRT3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], b
            je checkRT3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], b
            je checkRT3
            jmp Tcorner7
        checkRT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], r
            je moveBRW_T3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], r
            je moveBRW_T3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], r
            je moveBRW_T3
            jmp Tcorner7
    Tcorner7:
        checkWT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], w
            je checkBT7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], w
            je checkBT7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], w
            je checkBT7
            jmp Tcorner9
        checkBT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], b
            je checkRT7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], b
            je checkRT7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], b
            je checkRT7
            jmp Tcorner9
        checkRT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], r
            je moveBRW_T7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], r
            je moveBRW_T7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], r
            je moveBRW_T7
            jmp Tcorner9
    Tcorner9:
        checkWT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], w
            je checkBT9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], w
            je checkBT9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], w
            je checkBT9
            jmp Bcorner1
        checkBT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], b
            je checkRT9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], b
            je checkRT9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], b
            je checkRT9
            jmp Bcorner1
        checkRT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], r
            je moveBRW_T9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], r
            je moveBRW_T9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], r
            je moveBRW_T9
            jmp Bcorner1
    Bcorner1:
        checkWB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], w
            je checkBB1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], w
            je checkBB1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], w
            je checkBB1
            jmp Bcorner3
        checkBB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], b
            je checkRB1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], b
            je checkRB1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], b
            je checkRB1
            jmp Bcorner3
        checkRB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], r
            je doB1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], r
            je doB1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], r
            je doB1
            jmp Bcorner3
        doB1:
            call ralgoG
            jmp moveBRW_T1
    Bcorner3:
        checkWB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], w
            je checkBB3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], w
            je checkBB3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], w
            je checkBB3
            jmp Bcorner7
        checkBB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], b
            je checkRB3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], b
            je checkRB3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], b
            je checkRB3
            jmp Bcorner7
        checkRB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], r
            je doB3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], r
            je doB3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], r
            je doB3
            jmp Bcorner7
        doB3:
            call ralgoR
            jmp moveBRW_T3
    Bcorner7:
        checkWB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], w
            je checkBB7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], w
            je checkBB7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], w
            je checkBB7
            jmp Bcorner9
        checkBB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], b
            je checkRB7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], b
            je checkRB7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], b
            je checkRB7
            jmp Bcorner9
        checkRB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], r
            je doB7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], r
            je doB7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], r
            je doB7
            jmp Bcorner9
        doB7:
            call ralgoO
            jmp moveBRW_T7
    Bcorner9:
        call ralgoB
        jmp moveBRW_T9
    moveBRW_T1:
        call turnY
        call turnY
        rightyalgoT1:
            call ralgoB
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+8], w
        jne rightyalgoT1
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi+8], b
        jne rightyalgoT1
        jmp continue
    moveBRW_T3:
        call turnY
        rightyalgoT3:
            call ralgoB
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+8], w
        jne rightyalgoT3
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi+8], b
        jne rightyalgoT3
        jmp continue
    moveBRW_T7:
        call turnY
        call turnY
    call turnY
        rightyalgoT7:
            call ralgoB
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+8], w
        jne rightyalgoT7
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi+8], b
        jne rightyalgoT7
        jmp continue
    moveBRW_T9:
        rightyalgoT9:
            call ralgoB
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+8], w
        jne rightyalgoT9
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi+8], b
        jne rightyalgoT9
        jmp continue
    continue:
        ret
fixBRW ENDP

fixRGW proc
    Tcorner1:
        checkWT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], w
            je checkRT1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], w
            je checkRT1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], w
            je checkRT1
            jmp Tcorner3
        checkRT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], r
            je checkGT1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], r
            je checkGT1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], r
            je checkGT1
            jmp Tcorner3
        checkGT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], g
            je moveRGW_T1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], g
            je moveRGW_T1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], g
            je moveRGW_T1
            jmp Tcorner3
    Tcorner3:
        checkWT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], w
            je checkRT3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], w
            je checkRT3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], w
            je checkRT3
            jmp Tcorner7
        checkRT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], r
            je checkGT3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], r
            je checkGT3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], r
            je checkGT3
            jmp Tcorner7
        checkGT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], g
            je moveRGW_T3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], g
            je moveRGW_T3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], g
            je moveRGW_T3
            jmp Tcorner7
    Tcorner7:
        checkWT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], w
            je checkRT7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], w
            je checkRT7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], w
            je checkRT7
            jmp Tcorner9
        checkRT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], r
            je checkGT7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], r
            je checkGT7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], r
            je checkGT7
            jmp Tcorner9
        checkGT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], g
            je moveRGW_T7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], g
            je moveRGW_T7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], g
            je moveRGW_T7
            jmp Tcorner9
    Tcorner9:
        checkWT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], w
            je checkRT9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], w
            je checkRT9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], w
            je checkRT9
            jmp Bcorner1
        checkRT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], r
            je checkGT9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], r
            je checkGT9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], r
            je checkGT9
            jmp Bcorner1
        checkGT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], g
            je moveRGW_T9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], g
            je moveRGW_T9
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], g
            je moveRGW_T9
            jmp Bcorner1
    Bcorner1:
        checkWB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], w
            je checkRB1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], w
            je checkRB1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], w
            je checkRB1
            jmp Bcorner3
        checkRB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], r
            je checkGB1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], r
            je checkGB1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], r
            je checkGB1
            jmp Bcorner3
        checkGB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], g
            je doR1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], g
            je doR1
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], g
            je doR1
            jmp Bcorner3
        doR1:
            call ralgoO
            jmp moveRGW_T1
    Bcorner3:
        checkWB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], w
            je checkRB3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], w
            je checkRB3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], w
            je checkRB3
            jmp Bcorner7
        checkRB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], r
            je checkGB3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], r
            je checkGB3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], r
            je checkGB3
            jmp Bcorner7
        checkGB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], g
            je doR3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], g
            je doR3
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], g
            je doR3
            jmp Bcorner7
        doR3:
            call ralgoG
            jmp moveRGW_T3
    Bcorner7:
        checkWB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], w
            je checkRB7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], w
            je checkRB7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], w
            je checkRB7
            jmp Bcorner9
        checkRB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], r
            je checkGB7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], r
            je checkGB7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], r
            je checkGB7
            jmp Bcorner9
        checkGB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], g
            je doR7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], g
            je doR7
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], g
            je doR7
            jmp Bcorner9
        doR7:
            call ralgoB
            jmp moveRGW_T7
    Bcorner9:
        call ralgoR
        jmp moveRGW_T9
    moveRGW_T1:
        call turnY
        call turnY
        rightyalgoT1:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT1
        jmp continue
    moveRGW_T3:
        call turnY
        rightyalgoT3:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT3
        jmp continue
    moveRGW_T7:
        call turnY
        call turnY
        call turnY
        rightyalgoT7:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT7
        jmp continue
    moveRGW_T9:
        rightyalgoT9:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT9
        jmp continue
    continue:
        ret
fixRGW ENDP

fixGOW proc
    Tcorner1:
        checkWT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], w
            je checkGT1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], w
            je checkGT1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], w
            je checkGT1
            jmp Tcorner3
        checkGT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], g
            je checkOT1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], g
            je checkOT1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], g
            je checkOT1
            jmp Tcorner3
        checkOT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], o
            je moveGOW_T1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], o
            je moveGOW_T1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], o
            je moveGOW_T1
            jmp Tcorner3
    Tcorner3:
        checkWT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], w
            je checkGT3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], w
            je checkGT3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], w
            je checkGT3
            jmp Tcorner7
        checkGT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], g
            je checkOT3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], g
            je checkOT3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], g
            je checkOT3
            jmp Tcorner7
        checkOT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], o
            je moveGOW_T3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], o
            je moveGOW_T3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], o
            je moveGOW_T3
            jmp Tcorner7
    Tcorner7:
        checkWT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], w
            je checkGT7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], w
            je checkGT7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], w
            je checkGT7
            jmp Tcorner9
        checkGT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], g
            je checkOT7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], g
            je checkOT7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], g
            je checkOT7
            jmp Tcorner9
        checkOT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], o
            je moveGOW_T7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], o
            je moveGOW_T7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], o
            je moveGOW_T7
            jmp Tcorner9
    Tcorner9:
        checkWT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], w
            je checkGT9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], w
            je checkGT9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], w
            je checkGT9
            jmp Bcorner1
        checkGT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], g
            je checkOT9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], g
            je checkOT9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], g
            je checkOT9
            jmp Bcorner1
        checkOT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], o
            je moveGOW_T9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], o
            je moveGOW_T9
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], o
            je moveGOW_T9
            jmp Bcorner1
    Bcorner1:
        checkWB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], w
            je checkGB1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], w
            je checkGB1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], w
            je checkGB1
            jmp Bcorner3
        checkGB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], g
            je checkOB1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], g
            je checkOB1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], g
            je checkOB1
            jmp Bcorner3
        checkOB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], o
            je doG1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], o
            je doG1
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], o
            je doG1
            jmp Bcorner3
        doG1:
            call ralgoB
            jmp moveGOW_T1
    Bcorner3:
        checkWB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], w
            je checkGB3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], w
            je checkGB3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], w
            je checkGB3
            jmp Bcorner7
        checkGB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], g
            je checkOB3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], g
            je checkOB3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], g
            je checkOB3
            jmp Bcorner7
        checkOB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+6], o
            je doG3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+6], o
            je doG3
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+8], o
            je doG3
            jmp Bcorner7
        doG3:
            call ralgoO
            jmp moveGOW_T3
    Bcorner7:
        checkWB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], w
            je checkGB7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], w
            je checkGB7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], w
            je checkGB7
            jmp Bcorner9
        checkGB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], g
            je checkOB7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], g
            je checkOB7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], g
            je checkOB7
            jmp Bcorner9
        checkOB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], o
            je doG7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], o
            je doG7
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], o
            je doG7
            jmp Bcorner9
        doG7:
            call ralgoR
            jmp moveGOW_T7
    Bcorner9:
        call ralgoG
        jmp moveGOW_T9
    moveGOW_T1:
        call turnY
        call turnY
        rightyalgoT1:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT1
        jmp continue
    moveGOW_T3:
        call turnY
        rightyalgoT3:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT3
        jmp continue
    moveGOW_T7:
        call turnY
        call turnY
        call turnY
        rightyalgoT7:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT7
        jmp continue
    moveGOW_T9:
        rightyalgoT9:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT9
        jmp continue
    continue:
        ret
fixGOW ENDP

fixOBW proc
    Tcorner1:
        checkWT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], w
            je checkOT1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], w
            je checkOT1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], w
            je checkOT1
            jmp Tcorner3
        checkOT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], o
            je checkBT1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], o
            je checkBT1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], o
            je checkBT1
            jmp Tcorner3
        checkBT1:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+2], b
            je moveOBW_T1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi], b
            je moveOBW_T1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+2], b
            je moveOBW_T1
            jmp Tcorner3
    Tcorner3:
        checkWT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], w
            je checkOT3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], w
            je checkOT3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], w
            je checkOT3
            jmp Tcorner7
        checkOT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], o
            je checkBT3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], o
            je checkBT3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], o
            je checkBT3
            jmp Tcorner7
        checkBT3:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+8], b
            je moveOBW_T3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi], b
            je moveOBW_T3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+2], b
            je moveOBW_T3
            jmp Tcorner7
    Tcorner7:
        checkWT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], w
            je checkOT7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], w
            je checkOT7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], w
            je checkOT7
            jmp Tcorner9
        checkOT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], o
            je checkBT7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], o
            je checkBT7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], o
            je checkBT7
            jmp Tcorner9
        checkBT7:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi], b
            je moveOBW_T7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi], b
            je moveOBW_T7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+2], b
            je moveOBW_T7
            jmp Tcorner9
    Tcorner9:
        checkWT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], w
            je checkOT9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], w
            je checkOT9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], w
            je checkOT9
            jmp Bcorner1
        checkOT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], o
            je checkBT9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], o
            je checkBT9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], o
            je checkBT9
            jmp Bcorner1
        checkBT9:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], b
            je moveOBW_T9
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], b
            je moveOBW_T9
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], b
            je moveOBW_T9
            jmp Bcorner1
    Bcorner1:
        checkWB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], w
            je checkOB1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], w
            je checkOB1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], w
            je checkOB1
            jmp Bcorner3
        checkOB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], o
            je checkBB1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], o
            je checkBB1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], o
            je checkBB1
            jmp Bcorner3
        checkBB1:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+2], b
            je doO1
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+6], b
            je doO1
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+8], b
            je doO1
            jmp Bcorner3
        doO1:
            call ralgoR
            jmp moveOBW_T1
    Bcorner3:
        checkWB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], w
            je checkOB3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], w
            je checkOB3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], w
            je checkOB3
            jmp Bcorner7
        checkOB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], o
            je checkBB3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], o
            je checkBB3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], o
            je checkBB3
            jmp Bcorner7
        checkBB3:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi+8], b
            je doO3
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+6], b
            je doO3
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+8], b
            je doO3
            jmp Bcorner7
        doO3:
            call ralgoB
            jmp moveOBW_T3
    Bcorner7:
        checkWB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], w
            je checkOB7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], w
            je checkOB7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], w
            je checkOB7
            jmp Bcorner9
        checkOB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], o
            je checkBB7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], o
            je checkBB7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], o
            je checkBB7
            jmp Bcorner9
        checkBB7:
            mov esi, OFFSET sides + 9*w
            cmp byte ptr [esi], b
            je doO7
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+6], b
            je doO7
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+8], b
            je doO7
            jmp Bcorner9
        doO7:
            call ralgoG
            jmp moveOBW_T7
    Bcorner9:
        call ralgoO
        jmp moveOBW_T9
    moveOBW_T1:
        call turnY
        call turnY
        rightyalgoT1:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT1
        jmp continue
    moveOBW_T3:
        call turnY
        rightyalgoT3:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT3
        jmp continue
    moveOBW_T7:
        call turnY
        call turnY
        call turnY
        rightyalgoT7:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT7
        jmp continue
    moveOBW_T9:
        rightyalgoT9:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT9
        jmp continue
    continue:
        ret
fixOBW ENDP

ralgoB proc
    call turnR
    call turnY
    call turnR
    call turnR
    call turnR
    call turnY
    call turnY
    call turnY
	ret
ralgoB ENDP

ralgoO proc
    call turnB
    call turnY
    call turnB
    call turnB
    call turnB
    call turnY
    call turnY
    call turnY
	ret
ralgoO ENDP

ralgoG proc
    call turnO
    call turnY
    call turnO
    call turnO
    call turnO
    call turnY
    call turnY
    call turnY
	ret
ralgoG ENDP

ralgoR proc
    call turnG
    call turnY
    call turnG
    call turnG
    call turnG
    call turnY
    call turnY
    call turnY
	ret
ralgoR ENDP




; determine colors on side of desired color, turn both of those
turnMiddle PROC

turnMiddle ENDP
END main