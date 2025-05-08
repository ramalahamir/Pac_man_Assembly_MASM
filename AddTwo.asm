; Ramalah Amir (23i-2644) DS-4C

include irvine32.inc

; keeping the maze size constant for all levels
rows = 21
cols = 50
block_char  = '*'

.data
    ; reserving memory for maze in the memory
    ; +1 is for the null terminator at the end of each row for writeString
    maze byte rows * (cols + 1) dup(' ')   
    newline byte 0

    ; variables to store pacman's position
    rand_pos dword 0
    pacmanX dword 1
    pacmanY dword 1

    ; position of blocks inside the maze
    startX dword 0         
    startY dword 0

    ; variables to store the height and width of the block
    block_height dword 0
    block_width dword 0

.code
main proc
    call clrscr        ; clearing the screen
    call randomize     ; Re-seeds the random number generator

    call buildmaze
    call place_pacman
   ; call placeblocks
   call setBlocksSize
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

place_pacman proc
    ; preserving the old value
    push edi

    find_random_indexes:
        ; making the starting position random for pacman
        mov eax, rows - 2     ; getting random from 0 - 19
        call RandomRange      ; gives 0 - 18
        inc eax               ; gives 0 - 19
        mov pacmanY, eax      ; setting the row value for pacman

        mov eax, cols - 2     ; getting random from 0 - 48
        call RandomRange      ; gives 0 - 47
        inc eax               ; gives 0 - 48
        mov pacmanX, eax      ; setting the column value for pacman
    
    ; checking if the new position is empty or not to prevent overwriting

    ; calculating the 1d equivalent index in the maze
    mov  edi, offset maze 
    mov  eax, pacmanY
    imul eax, cols + 1     
    add  eax, pacmanX     
    add  edi, eax       

    mov al, byte ptr [edi]   ; loading whatever’s already in that position
    cmp al, ' '              ; checking if its empty or not
    jne  try_again           ; if not find new position for pac man

    mov byte ptr [edi], 'P'  ; if its empty, place Pacman here
    jmp done_placing

    try_again:
        ; jump back up to pick new random indexes
        jmp find_random_indexes

    done_placing:
        pop edi
    ret
place_pacman endp

draw_box proc
    ; preserving values
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov ecx, 0          ; for first row

draw_box_rows: 
    mov eax, startY     ; first row
    add eax, ecx        ; eax will be storing the current row
    mov edx, eax        ; save row in edx

    mov eax, startX     ; starting column
    mov esi, eax        ; starting column will be same for each row

    mov ebx, block_width  ; total column

    draw_box_cols:
        ; calculate 1D index for the maze
        mov edi, offset maze
        mov eax, edx                ; getting the row
        imul eax, cols + 1          
        add eax, esi                ; getting the column
        add edi, eax                ; 1D index

        ; draw character at this position
        mov al, block_char
        mov byte ptr [edi], al

        inc esi
        dec ebx              ; stopping the loop as soon as the columns are completed
        jnz draw_box_cols

    inc ecx                  ; getting the next row
    cmp ecx, block_height    ; total block height
    jne draw_box_rows

    ; getting the original values
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
draw_box endp

setBlocksSize proc
    ; pick random height (max height of block will be 3)
    mov   eax, 3    
    call  RandomRange    
    inc   eax            
    mov   block_height, eax

    ; pick random width (max width of block will be 10)
    mov   eax, 10
    call  RandomRange
    inc   eax
    mov   block_width, eax

    mov startX, 7
    mov startY, 7
    call draw_box

setBlocksSize endp

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
