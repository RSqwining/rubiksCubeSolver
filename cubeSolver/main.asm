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
shuffle byte 13, 10, "End of shuffling", 13, 10, 13, 10

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

    ;Use turn functions and turn algorithms to shuffle cube
    call ralgoB
    call Yfacealgo
    call lalgoR
    call ralgoR
    call Yfacealgo
    call lalgoG
    call Yfacealgo
    call ralgoG
    call turnY
    call Yfacealgo
    call lalgoO
    call turnB
    call Yfacealgo
    call ralgoO
    call Yfacealgo
    call lalgoB
    call turnW
    mov eax, filehandle
	mov ecx, SIZEOF shuffle
    mov edx, OFFSET shuffle
	call WriteToFile
	call displayCube
	call makeDaisy
	call displayCube
	call solveWEdges
	call displayCube
	call makeFLayer
	call displayCube
    call makeSLayer
	call displayCube
    call yellowPlus
    call displayCube
    call movTCorner
    call displayCube
    call fixYface
    call displayCube
    call finalStep
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
        mov esi, OFFSET sides + 9*r
        cmp byte ptr [esi+8], r
        jne rightyalgoT1
        jmp continue
    moveRGW_T3:
        call turnY
        rightyalgoT3:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT3
        mov esi, OFFSET sides + 9*r
        cmp byte ptr [esi+8], r
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
        mov esi, OFFSET sides + 9*r
        cmp byte ptr [esi+8], r
        jne rightyalgoT7
        jmp continue
    moveRGW_T9:
        rightyalgoT9:
            call ralgoR
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+2], w
        jne rightyalgoT9
        mov esi, OFFSET sides + 9*r
        cmp byte ptr [esi+8], r
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
        mov esi, OFFSET sides + 9*g
        cmp byte ptr [esi+8], g
        jne rightyalgoT1
        jmp continue
    moveGOW_T3:
        call turnY
        rightyalgoT3:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT3
        mov esi, OFFSET sides + 9*g
        cmp byte ptr [esi+8], g
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
        mov esi, OFFSET sides + 9*g
        cmp byte ptr [esi+8], g
        jne rightyalgoT7
        jmp continue
    moveGOW_T9:
        rightyalgoT9:
            call ralgoG
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi], w
        jne rightyalgoT9
        mov esi, OFFSET sides + 9*g
        cmp byte ptr [esi+8], g
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
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+8], o
        jne rightyalgoT1
        jmp continue
    moveOBW_T3:
        call turnY
        rightyalgoT3:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT3
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+8], o
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
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+8], o
        jne rightyalgoT7
        jmp continue
    moveOBW_T9:
        rightyalgoT9:
            call ralgoO
        mov esi, OFFSET sides + 9*w
        cmp byte ptr [esi+6], w
        jne rightyalgoT9
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+8], o
        jne rightyalgoT9
        jmp continue
    continue:
        ret
fixOBW ENDP

makeSLayer proc
    start:
        BRedge:
            BRstep1:
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+5], b
                je BRstep2
                jmp Tedge2
            BRstep2:
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+3], r
                je RGedge
                jmp Tedge2
        RGedge:
            RGstep1:
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+5], r
                je RGstep2
                jmp Tedge2
            RGstep2:
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+3], g
                je GOedge
                jmp Tedge2
        GOedge:
            GOstep1:
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+5], g
                je GOstep2
                jmp Tedge2
            GOstep2:
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+3], o
                je OBedge
                jmp Tedge2
        OBedge:
            OBstep1:
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+5], o
                je OBstep2
                jmp Tedge2
            OBstep2:
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+3], b
                je continue
                jmp Tedge2
    Tedge2:
        yellow2:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+1], y
            jne color2
            jmp Tedge4
        color2:
            mov esi, OFFSET sides + 9*g
            cmp byte ptr [esi+1], y
            jne foundedge2
            jmp Tedge4
    Tedge4:
        yellow4:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+3], y
            jne color4
            jmp Tedge6
        color4:
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+1], y
            jne foundedge4
            jmp Tedge6
    Tedge6:
        yellow6:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+5], y
            jne color6
            jmp Tedge8
        color6:
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+1], y
            jne foundedge6
            jmp Tedge8
    Tedge8:
        yellow8:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+7], y
            jne color8
            jmp popedgeup
        color8:
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+1], y
            jne foundedge8
            jmp popedgeup
    foundedge2:
        checkBRO2:
            checkB2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], b
                je checkRB2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], b
                je checkRB2
                jmp checkGRO2
            checkRB2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], r
                je movRTBB2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], r
                je movRBBT2
            checkOB2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], o
                je movOTBB2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], o
                je movOBBT2
            movRTBB2:
                call turnY
                call turnY
                call turnY
                call ralgoB
                call lalgoR
                inc al
                jmp start
            movRBBT2:
                call lalgoR
                call ralgoB
                inc al
                jmp start
            movOTBB2:
                call turnY
                call lalgoB
                call ralgoO
                inc al
                jmp start
            movOBBT2:
                call ralgoO
                call lalgoB
                inc al
                jmp start
        checkGRO2:
            checkG2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], g
                je checkRG2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], g
                je checkRG2
            checkRG2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], r
                je movRTGB2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], r
                je movRBGT2
            checkOG2:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+1], o
                je movOTGB2
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+1], o
                je movOBGT2
            movRTGB2:
                call turnY
                call turnY
                call turnY
                call lalgoG
                call ralgoR
                inc al
                jmp start
            movRBGT2:
                call turnY
                call turnY
                call ralgoR
                call lalgoG
                inc al
                jmp start
            movOTGB2:
                call turnY
                call ralgoG
                call lalgoO
                inc al
                jmp start
            movOBGT2:
                call turnY
                call turnY
                call lalgoO
                call ralgoG
                inc al
                jmp start
    foundedge4:
        checkBRO4:
            checkB4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], b
                je checkRB4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], b
                je checkRB4
                jmp checkGRO4
            checkRB4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], r
                je movRTBB4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], r
                je movRBBT4
            checkOB4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], o
                je movOTBB4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], o
                je movOBBT4
            movRTBB4:
                call ralgoB
                call lalgoR
                inc al
                jmp start
            movRBBT4:
                call turnY
                call lalgoR
                call ralgoB
                inc al
                jmp start
            movOTBB4:
                call turnY
                call turnY
                call lalgoB
                call ralgoO
                inc al
                jmp start
            movOBBT4:
                call turnY
                call ralgoO
                call lalgoB
                inc al
                jmp start
        checkGRO4:
            checkG4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], g
                je checkRG4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], g
                je checkRG4
            checkRG4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], r
                je movRTGB4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], r
                je movRBGT4
            checkOG4:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+3], o
                je movOTGB4
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+1], o
                je movOBGT4
            movRTGB4:
                call lalgoG
                call ralgoR
                inc al
                jmp start
            movRBGT4:
                call turnY
                call turnY
                call turnY
                call ralgoR
                call lalgoG
                inc al
                jmp start
            movOTGB4:
                call turnY
                call turnY
                call ralgoG
                call lalgoO
                inc al
                jmp start
            movOBGT4:
                call turnY
                call turnY
                call turnY
                call lalgoO
                call ralgoG
                inc al
                jmp start
    foundedge6:
        checkBRO6:
            checkB6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], b
                je checkRB6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], b
                je checkRB6
                jmp checkGRO4
            checkRB6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], r
                je movRTBB6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], r
                je movRBBT6
            checkOB6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], o
                je movOTBB6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], o
                je movOBBT6
            movRTBB6:
                call turnY
                call turnY
                call ralgoB
                call lalgoR
                inc al
                jmp start
            movRBBT6:
                call turnY
                call turnY
                call turnY
                call lalgoR
                call ralgoB
                inc al
                jmp start
            movOTBB6:
                call lalgoB
                call ralgoO
                inc al
                jmp start
            movOBBT6:
                call turnY
                call turnY
                call turnY
                call ralgoO
                call lalgoB
                inc al
                jmp start
        checkGRO6:
            checkG6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], g
                je checkRG6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], g
                je checkRG6
            checkRG6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], r
                je movRTGB6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], r
                je movRBGT6
            checkOG6:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+5], o
                je movOTGB6
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+1], o
                je movOBGT6
            movRTGB6:
                call turnY
                call turnY
                call lalgoG
                call ralgoR
                inc al
                jmp start
            movRBGT6:
                call turnY
                call ralgoR
                call lalgoG
                inc al
                jmp start
            movOTGB6:
                call ralgoG
                call lalgoO
                inc al
                jmp start
            movOBGT6:
                call turnY
                call lalgoO
                call ralgoG
                inc al
                jmp start
    foundedge8:
        checkBRO8:
            checkB8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], b
                je checkRB8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], b
                je checkRB8
                jmp checkGRO8
            checkRB8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], r
                je movRTBB8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], r
                je movRBBT8
            checkOB8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], o
                je movOTBB8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], o
                je movOBBT8
            movRTBB8:
                call turnY
                call ralgoB
                call lalgoR
                inc al
                jmp start
            movRBBT8:
                call turnY
                call turnY
                call lalgoR
                call ralgoB
                inc al
                jmp start
            movOTBB8:
                call turnY
                call turnY
                call turnY
                call lalgoB
                call ralgoO
                inc al
                jmp start
            movOBBT8:
                call turnY
                call turnY
                call ralgoO
                call lalgoB
                inc al
                jmp start
        checkGRO8:
            checkG8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], g
                je checkRG8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], g
                je checkRG8
            checkRG8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], r
                je movRTGB8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], r
                je movRBGT8
            checkOG8:
                mov esi, OFFSET sides + 9*y
                cmp byte ptr [esi+7], o
                je movOTGB8
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+1], o
                je movOBGT8
            movRTGB8:
                call turnY
                call lalgoG
                call ralgoR
                inc al
                jmp start
            movRBGT8:
                call ralgoR
                call lalgoG
                inc al
                jmp start
            movOTGB8:
                call turnY
                call turnY
                call turnY
                call ralgoG
                call lalgoO
                inc al
                jmp start
            movOBGT8:
                call lalgoO
                call ralgoG
                inc al
                jmp start
    popedgeup:
        BRedgecheck:
            BRstep1check:
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+5], b
                je BRstep2check
                jmp popBRedge
            BRstep2check:
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+3], r
                je RGedgecheck
                jmp popBRedge
        RGedgecheck:
            RGstep1check:
                mov esi, OFFSET sides + 9*r
                cmp byte ptr [esi+5], r
                je RGstep2check
                jmp popRGedge
            RGstep2check:
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+3], g
                je GOedgecheck
                jmp popRGedge
        GOedgecheck:
            GOstep1check:
                mov esi, OFFSET sides + 9*g
                cmp byte ptr [esi+5], g
                je GOstep2check
                jmp popGOedge
            GOstep2check:
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+3], o
                je OBedgecheck
                jmp popGOedge
        OBedgecheck:
            OBstep1check:
                mov esi, OFFSET sides + 9*o
                cmp byte ptr [esi+5], o
                je OBstep2check
                jmp popOBedge
            OBstep2check:
                mov esi, OFFSET sides + 9*b
                cmp byte ptr [esi+3], b
                je start ;;if this ever executes then some issue
                jmp popOBedge
        popBRedge:
            call ralgoB
            call lalgoR
            jmp start
        popRGedge:
            call ralgoR
            call lalgoG
            jmp start
        popGOedge:
            call ralgoG
            call lalgoO
            jmp start
        popOBedge:
            call ralgoO
            call lalgoB
            jmp start
    continue:
        ret
makeSLayer ENDP


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

lalgoB proc
    call turnO
    call turnO
    call turnO
    call turnY
    call turnY
    call turnY
    call turnO
    call turnY
    ret
lalgoB ENDP

lalgoO proc
    call turnG
    call turnG
    call turnG
    call turnY
    call turnY
    call turnY
    call turnG
    call turnY
    ret
lalgoO ENDP

lalgoG proc
    call turnR
    call turnR
    call turnR
    call turnY
    call turnY
    call turnY
    call turnR
    call turnY
    ret
lalgoG ENDP

lalgoR proc
    call turnB
    call turnB
    call turnB
    call turnY
    call turnY
    call turnY
    call turnB
    call turnY
    ret
lalgoR ENDP


yellowPlus proc
    mov al, 0
    yedge1:
        mov esi, OFFSET sides + 9*y
        cmp byte ptr [esi+1], y
        je inc1
    yedge3:
        cmp byte ptr [esi+3], y
        je inc3
    yedge5:
        cmp byte ptr [esi+5], y
        je inc5
    yedge7:
        cmp byte ptr [esi+7], y
        je inc7
        jmp casefinder
    inc1:
        add al, 1
        jmp yedge3
    inc3:
        add al, 2
        jmp yedge5
    inc5:
        add al, 4
        jmp yedge7
    inc7:
        add al, 8
    casefinder:
        cmp al, 15
        je case1
        cmp al, 9
        je case2
        cmp al, 6
        je case3
        cmp al, 12
        je case4
        cmp al, 5
        je case5
        cmp al, 3
        je case6
        cmp al, 10
        je case7
        cmp al, 0
        je case8
    case1:;y=>1,3,5,7 (+)
        jmp continue
    case2:;y=>1,7 (L)
        call turnY
    case3:;y=>3,5 (L)
        call turnB
        call ralgoB
        call turnB
        call turnB
        call turnB
        jmp continue
    case4:;y=>5,7 (r)
        call turnG
        call turnY
        call turnO
        call turnY
        call turnY
        call turnY
        call turnO
        call turnO
        call turnO
        call turnG
        call turnG
        call turnG
        jmp continue
    case5:;y=>1,5 (r)
        call turnY
    case6:;y=>1,3 (r)
        call turnY
    case7:;y=>3,7 (r)
        call turnY
        call case4
    case8:;y=>4(always) (*) 
        call turnB
        call ralgoB
        call turnB
        call turnB
        call turnB
        call case4
    continue:
        ret
yellowPlus ENDP

movTCorner proc
    dofirst: ;;BOY: 8, BRY: 6, GRY: 8, OGY: 10
        mov esi, OFFSET sides + 9*y
        cmp byte ptr [esi+6], b
        je nextcolor
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi], b
        je nextcolor
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+2], b
        je nextcolor
        call turnY
        jmp dofirst
        nextcolor:
            mov esi, OFFSET sides + 9*y
            cmp byte ptr [esi+6], o
            je nextsteps
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi], o
            je nextsteps
            mov esi, OFFSET sides + 9*o
            cmp byte ptr [esi+2], o
            je nextsteps
            call turnY
            jmp dofirst
    nextsteps: ;;BOY now in [esi+6]
        ;;assume BRY in [esi]
        mov al, 0
        mov esi, OFFSET sides + 9*y
        add al, byte ptr [esi]
        mov esi, OFFSET sides + 9*o
        add al, byte ptr [esi]
        mov esi, OFFSET sides + 9*g
        add al, byte ptr [esi+2]
        cmp al, 6
        je doublerotBR
        ;;assume BRY in [esi+2]
        mov al, 0
        mov esi, OFFSET sides + 9*y
        add al, byte ptr [esi+2]
        mov esi, OFFSET sides + 9*g
        add al, byte ptr [esi]
        mov esi, OFFSET sides + 9*r
        add al, byte ptr [esi+2]
        cmp al, 6
        je singlerotBR
    ;;BRY in [esi+8], so check GRY and GOY
    nextstepG:
        mov al, 0
        mov esi, OFFSET sides + 9*y
        add al, byte ptr [esi+2]
        mov esi, OFFSET sides + 9*g
        add al, byte ptr [esi]
        mov esi, OFFSET sides + 9*r
        add al, byte ptr [esi+2]
        cmp al, 8
        je continue
        call ralgoR
        call ralgoR
        call ralgoR
        call lalgoG
        call lalgoG
        call turnR
        call turnR
        call turnR
        call turnY
        call turnY
        call turnY
        call turnR
        jmp continue
    doublerotBR:
        mov al, 0
        mov esi, OFFSET sides + 9*y
        add al, byte ptr [esi+2]
        mov esi, OFFSET sides + 9*g
        add al, byte ptr [esi]
        mov esi, OFFSET sides + 9*r
        add al, byte ptr [esi+2]
        cmp al, 10
        je option1
        jmp option2
        option1: ;;BRY in [esi], GOY in [esi+2], GRY in [esi+8]
            call ralgoR
            call ralgoR
            call ralgoR
            call lalgoG
            call lalgoG
            call turnR
            call turnR
            call turnR
            call turnY
            call turnY
            call turnY
            call turnR ;; swap BRY and OGY
            call ralgoB
            call ralgoB
            call ralgoB
            call lalgoR
            call lalgoR
            call turnB
            call turnB
            call turnB
            call turnY
            call turnY
            call turnY
            call turnB ;;swap BRY and GRY
            jmp continue 
        option2: ;;BRY in [esi], GOY in [esi+8], GRY in [esi+2]
            call ralgoB
            call ralgoB
            call ralgoB
            call lalgoR
            call lalgoR
            call turnB
            call turnB
            call turnB
            call turnY
            call turnY
            call turnY
            call turnB ;; swap GOY and GRY
            jmp option1
    singlerotBR: ;; BRY in [esi+2]
        call ralgoB
        call ralgoB
        call ralgoB
        call lalgoR
        call lalgoR
        call turnB
        call turnB
        call turnB
        call turnY
        call turnY
        call turnY
        call turnB ;;swap BRY and [esi+8]
        jmp nextstepG ;;this should swap [esi] and [esi+8] if necessary
    continue:
        ret
movTCorner ENDP

Yfacealgo proc
    call turnO
    call turnW
    call turnO
    call turnO
    call turnO
    call turnW
    call turnW
    call turnW
    ret
Yfacealgo ENDP

fixYface proc
    mov bl, 0
    findyellow:
        mov al, 0
        mov esi, OFFSET sides +9*y
        add al, [esi]
        add al, [esi+2]
        add al, [esi+6]
        add al, [esi+8]
        cmp al, 4
        je continue
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+2], y
        je fixYv2
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi], y
        je fixYv4
        call turnY
        call turnY
        call turnY
        inc bl
        jmp findyellow
    fixYv4:
        call Yfacealgo
        call Yfacealgo
    fixYv2:
        call Yfacealgo
        call Yfacealgo
        call turnY
        call turnY
        call turnY
        inc bl
        jmp findyellow
    continue:
        l1:
            cmp bl, 4
            jae finishproc
            call turnY
            call turnY
            call turnY
            inc bl
            jmp l1
        finishproc:
            ret
fixYface ENDP

finalstep proc
    checkalldone:
        bdone:
            mov esi, OFFSET sides + 9*b
            cmp byte ptr [esi+1], b
            je rdone
            jne bside
        rdone:
            mov esi, OFFSET sides + 9*r
            cmp byte ptr [esi+1], r
            je continue
    bside:
        mov esi, OFFSET sides + 9*b
        cmp byte ptr [esi+1], b
        jne rside
        je fixcubeB
    rside:
        mov esi, OFFSET sides + 9*r
        cmp byte ptr [esi+1], r
        jne gside
        je fixcubeR
    gside:
        mov esi, OFFSET sides + 9*g
        cmp byte ptr [esi+1], g
        jne oside
        je fixcubeG
    oside:
        mov esi, OFFSET sides + 9*o
        cmp byte ptr [esi+1], o
        jne fixcubeB
        je fixcubeO
    fixcubeB:
        call ralgoB
        call lalgoB
        call ralgoB
        call ralgoB
        call ralgoB
        call ralgoB
        call ralgoB
        call lalgoB
        call lalgoB
        call lalgoB
        call lalgoB
        call lalgoB
        jmp checkalldone
    fixcubeR:
        call ralgoR
        call lalgoR
        call ralgoR
        call ralgoR
        call ralgoR
        call ralgoR
        call ralgoR
        call lalgoR
        call lalgoR
        call lalgoR
        call lalgoR
        call lalgoR
        jmp checkalldone
    fixcubeO:
        call ralgoO
        call lalgoO
        call ralgoO
        call ralgoO
        call ralgoO
        call ralgoO
        call ralgoO
        call lalgoO
        call lalgoO
        call lalgoO
        call lalgoO
        call lalgoO
        jmp checkalldone
    fixcubeG:
        call ralgoG
        call lalgoG
        call ralgoG
        call ralgoG
        call ralgoG
        call ralgoG
        call ralgoG
        call lalgoG
        call lalgoG
        call lalgoG
        call lalgoG
        call lalgoG
        jmp checkalldone
    continue:
        ret
finalstep ENDP

; determine colors on side of desired color, turn both of those
turnMiddle PROC

turnMiddle ENDP
END main