.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD 

INCLUDE Irvine32.inc

.data
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
	
	mov esi, OFFSET sides + 9 * g
	call turnClock

	call displayCube
	
	INVOKE ExitProcess, 0
main ENDP

initCube proc 
	ret
initCube ENDP

displayCube proc

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

ret
displayCube ENDP

printSide PROC
	push esi
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
	pop esi
	ret
printSide ENDP

turnW PROC
mov esi, OFFSET sides
call turnClock
ret
turnW ENDP

turnY PROC
mov esi, OFFSET sides + 9*y
call turnClock
ret
turnY ENDP

turnB PROC
mov esi, OFFSET sides + 9*b
call turnClock
ret
turnB ENDP

turnR PROC
mov esi, OFFSET sides + 9*r
call turnClock
ret
turnR ENDP

turnG PROC
mov esi, OFFSET sides + 9*g
call turnClock
ret
turnG ENDP

turnO PROC
mov esi, OFFSET sides + 9*o
call turnClock
ret
turnO ENDP



;clockwise turn 
turnClock PROC
	push esi

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

	cmp al, w; check the color of the center and set al to the opposing color value, white and yellow are similar to handle
	je wC
	cmp al, y
	jne nwy; no white yellow

	yC:
	mov esi, OFFSET sides + 9 * b; set esi to point to the 1st element in blue array
	mov edi, OFFSET sides + 9 * r; set edi to point to the 1st element in red array
	jmp ywC

	wC:
	mov esi, OFFSET sides + 9 * b + 6; set esi to point to the 7th element in blue array
	mov edi, OFFSET sides + 9 * r + 6; set edi to point to the 7th element in red array
	jmp ywC

	ywC:
	mov ecx, 3;
	push esi
	push edi
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
	pop esi
	pop edi
	jmp aCC; jump after check center


	nwy:

	cmp al, g
	je gC

	cmp al, b
	jne nbg

	bC:
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
	jmp aCC; jump after check center

	gC:
	mov esi, OFFSET sides + 9 * r + 2; use pointer for orange / red
	mov edi, OFFSET sides; use pointer for white/yellow
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
	jne aCC; jump after check center
 
	nbg:
	cmp al, o
	je oC
	cmp al, r
	je rC

	oC:
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



	jmp aCC; jump after check center

	rC:
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
	jmp aCC; jump after check center

	aCC:



	
	pop esi
	ret
	
turnClock ENDP

; determine colors on side of desired color, turn both of those
turnMiddle PROC

turnMiddle ENDP
END main