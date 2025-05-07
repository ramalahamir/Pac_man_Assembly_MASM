; Ramalah Amir (23i-2644) DS-4C

include irvine32.inc

; keeping the maze size constant for all levels
rows = 21
cols = 50

.data
    ; reserving memory for maze in the memory
    ; +1 is for the null terminator at the end of each row for writeString
    maze byte rows * (cols + 1) dup(' ')   
    newline byte 0

    ; variables to store pacman's position
    pacmanX dword 1
    pacmanY dword 1

.code
main proc
    ; clearing the screen
    call clrscr
    call buildmaze
  ;  call placeplayer
   ; call placeblocks
    call drawmaze

  ;  gameloop:
   ;     call readkey
    ;    cmp al, 0
     ;   jne gameloop
 ;       call handleinput
  ;      call clrscr
   ;     call drawmaze
    ;    jmp gameloop
main endp

; translating the 2D coordinates into a single 1D index with
; formula: current_row * total_columns + current_column

; setting the boundaries
buildmaze proc
    mov ecx, rows   ; keeping track of how many rows to fill
    mov esi, 0      ; current row number

    nextrow:
        mov edi, offset maze         ; edi will be storing the current column = 0 in the beginning
        mov eax, esi                 ; esi stores the row index
        imul eax, cols + 1           ; doing current_row * total_columns
        add edi, eax                 ; doing + current_column and getting the 2d index at edi 

        ; total columns
        mov ebx, cols

        ; comparing row number whether to draw boundary or space
        cmp ecx, rows   ; first row
        je boundary

        second_compare:
            cmp ecx, 1   ; last row
            je boundary

        mov al, ' '   ; filling the maze with space
        jmp fillrow

        boundary:
            mov al, '#'  ; print boundary

        ; loop to fill the current row
        fillrow:
            mov byte ptr [edi], al    ; print at the calculated 2d index converted to 1d index
            inc edi
            dec ebx                   ; keep track of columns
            jnz fillrow               ; keep filling the row until the columns are completed

            mov byte ptr [edi], 0     ; adding the null terminater at the end of the row

            ; same thing calculate the index again for the same row
            ; for Adding side walls for middle rows
            mov edi, offset maze
            mov eax, esi               ; same row since esi didn't change
            imul eax, cols + 1
            add edi, eax

            ; first check if it isn't the top or bottom wall
            cmp esi, 0
            je skiprow
            cmp esi, rows - 1
            je skiprow

            ; print boundary at first col and last col
            mov byte ptr [edi], '#'
            mov byte ptr [edi + cols - 1], '#'

            ; jump to next row
            jmp skiprow          

            skiprow:
                inc esi
    loop nextrow
    ret
buildmaze endp

placeplayer proc
    mov eax, 1
    mov pacmanY, eax
    mov pacmanX, eax
    mov al, 'p'
    call setmazechar
    ret
placeplayer endp

setmazechar proc
    ; input: pacmanX, pacmanY, char in al
    push edi
    mov edi, offset maze
    mov eax, pacmanY
    imul eax, cols + 1
    add eax, pacmanX
    add edi, eax
    mov byte ptr [edi], al
    pop edi
    ret
setmazechar endp

placeblocks proc
    mov ecx, 10
nextblock:
    call randomrangey
    mov pacmanY, eax
    call randomrangex
    mov pacmanX, eax
    mov al, '*'
    call setmazechar
    loop nextblock
    ret
placeblocks endp

randomrangex proc
    ; returns 1 to cols - 2
    mov eax, cols - 2
    call randomrange
    inc eax
    ret
randomrangex endp

randomrangey proc
    ; returns 1 to rows - 2
    mov eax, rows - 2
    call randomrange
    inc eax
    ret
randomrangey endp

drawmaze proc
    ; storing the values of ecx and edx in stack
    push ecx
    push edx
    mov ecx, 0      ; starting row 

    nextrow:
        ; calculating index using ebx because edx will be used by gotoxy
        mov ebx, offset maze
        mov eax, ecx
        imul eax, cols + 1
        add ebx, eax

        ; storing the x and y positions for positioning cursor using gotoxy
        mov dh, cl     ; storing row
        mov dl, 0      ; storing col
        call gotoxy

        mov edx, ebx
        call writestring    ; writing whole string (single row) till null terminator

        
        inc ecx               ; increment row 
        cmp ecx, rows         ; see if all rows are completed or not
        jl nextrow            ; if not loop again till all rows are completed
    
    ; restore the original values
    pop edx
    pop ecx
    ret
drawmaze endp

; movement and collision logic to be added
handleinput proc
    ; placeholder for movement logic
    ret
handleinput endp

end main
