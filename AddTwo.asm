; Ramalah Amir (23i-2644) DS-4C

include irvine32.inc

; keeping the maze size constant for all levels
rows = 21
cols = 55
row_start_point = 6
col_start_point = 20
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

    ; welcome screen setup
    welcomeMsg  byte "WELCOME TO PAC-MAN GAME!", 0
    inputMsg    byte "Please enter your name: ", 0
    helloMsg    byte "Hello, ", 0
    userName    byte 50 dup(0)       
    topBorder   byte "+======================================+",0
    sideBorder  byte "|                                      |",0
    bottomBorder byte "+======================================+",0

    ; game menue screen
    menuTitle    byte "   GAME MENU   ", 0
    opt1         byte "1. Start Game", 0
    opt2         byte "2. Highest Score", 0
    opt3         byte "3. Instructions", 0
    opt4         byte "4. Exit", 0
    select_optionMsg    byte "Select option (1-4): ", 0

    ; for main game screen
    score_txt byte "SCORE: ", 0
    lives_txt byte "LIVES: ", 0
    score dword 0
    lives byte 3

    ; msgs
    exitGameBool byte 0
    exittingMsg byte "Exiting Game...... :)", 0
    invalidMsg byte "Invalid Option entered, Try Again..... :(", 0

    ; instruction screen
    instrTitle byte "   INSTRUCTIONS   ", 0
    instrLine1 byte "Use arrow keys to move Pac-Man", 0
    instrLine2 byte "Collect all dots (.) to win", 0
    instrLine3 byte "Avoid ghosts (@ % & $)", 0
    instrLine4 byte "Press Q anytime to quit", 0
    instrPrompt byte 0Dh,0Ah, "Press 'r' to return...",0

    ; making a temp variable
    temp dword 0

.code
main proc
    call randomize     ; Re-seeds the random number generator

    ; calling screens
    call welcomeScreen
    call gameMenuScreen

    call clrscr

    ; building the game main screen
    call buildmaze
   ; call placeblocks
    call setBlocksSize
    call place_pacman
    call drawmaze

     gameLoop:
        call ReadKey
        cmp  al, 0
        jne  gameLoop        ; wait for a special key
        call pacman_movement     ; moves Pac-Man and updates score
       ; call drawmaze
        jmp  gameLoop

    ; global label
    cmp exitGameBool, 1    ; if exit is triggered only then displey the exitMsg
    jne finish

    exit_game:: 
        call clrscr
        mov  edx, offset exittingMsg
        mov  eax, green+(yellow*16)
        call SetTextColor
        call writeString

        mov  eax, white+(black*16)
        call SetTextColor

    finish:
        exit
main endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

welcomeScreen proc
    call clrscr        ; clearing the screen
    ; top border 
    mov  eax, green+(black*16)
    call SetTextColor

    ; positioning the start point
    mov  dh, 2       ; row
    mov  dl, 10      ; col
    call gotoxy
    mov  edx, offset topBorder
    call WriteString

    ; side borders drawn on 3 rows starting from row 3 to row 5
    mov  ecx, 3
    drawSides:
        mov  dh, cl   ; row
        mov  dl, 10   ; col
        call gotoxy
        mov  edx, offset sideBorder
        call WriteString
        inc  cl
        cmp  cl, 6    
        jl   drawSides

    ; bottom border at row 6
    mov  dh, 6    ; row
    mov  dl, 10   ; col
    call gotoxy
    mov  edx, offset bottomBorder
    call WriteString

    ; welcome Msg
    mov  eax, yellow+(black*16)
    call SetTextColor
    mov  dh, 4      ; row
    mov  dl, 18     ; col
    call gotoxy
    mov  edx, offset welcomeMsg
    call WriteString

    ; inputMsg
    mov  eax, yellow+(green*16)
    call SetTextColor
    mov  dh, 8    ; row
    mov  dl, 10   ; col
    call gotoxy
    mov  edx, offset inputMsg
    call WriteString

    ; read name
    mov edx, offset userName
    mov  ecx, lengthof userName
    call ReadString

    ; greet the user
    call CrLf
    mov  dh, 9   ; row
    mov  dl, 10   ; col
    call gotoxy
    mov  edx, offset helloMsg
    call WriteString
    mov  edx, offset userName
    call WriteString
    call CrLf

    ; reset colors
    mov  eax, white+(black*16)
    call SetTextColor
    call WaitMsg       ; wait till the user presses some key
    ret
welcomeScreen endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gameMenuScreen proc
    returnToMenu::
        call clrscr

        ; top border 
        mov  eax, green+(black*16)
        call SetTextColor

        ; positioning the start point
        mov  dh, 2       ; row
        mov  dl, 10      ; col
        call gotoxy
        mov  edx, offset topBorder
        call WriteString

        ; side borders drawn on 6 rows starting from row 3 to row 5
        mov  ecx, 3
        drawSides:
            mov  dh, cl   ; row
            mov  dl, 10   ; col
            call gotoxy
            mov  edx, offset sideBorder
            call WriteString
            inc  cl
            cmp  cl, 6    
            jl   drawSides

        ; bottom border at row 6
        mov  dh, 6    ; row
        mov  dl, 10   ; col
        call gotoxy
        mov  edx, offset bottomBorder
        call WriteString

        ; printing the menu title
        mov  eax, yellow +(black*16)
        call SetTextColor
        mov  dh, 4       ; row
        mov  dl, 22      ; col
        call gotoxy
        mov  edx, offset menuTitle
        call WriteString

        ; printing options
        mov  eax, yellow+(green*16)
        call SetTextColor

        mov  dh, 8
        mov  dl, 22
        call gotoxy
        mov  edx, offset opt1
        call WriteString

        mov  dh, 9
        mov  dl, 22
        call gotoxy
        mov  edx, offset opt2
        call WriteString

        mov  dh, 10
        mov  dl, 22
        call gotoxy
        mov  edx, offset opt3
        call WriteString

        mov  dh, 11
        mov  dl, 22
        call gotoxy
        mov  edx, offset opt4
        call WriteString

        ; select option msg
        mov  eax, yellow+(black*16)
        call SetTextColor
        mov  dh, 13
        mov  dl, 20
        call gotoxy
        mov  edx, offset select_optionMsg
        call WriteString

        ; read a single key  
        call ReadChar        ; stored in eax

        cmp al, '1'
        je return_to_main
        cmp al, '2'
        ;je highScore
        cmp al, '3'
        ;je instructions
        cmp al, '4'
        je exit_game

        instructions:
            call InstructionScreen

        incorrectOption:
            call clrscr
            mov edx, offset invalidMsg
            mov  eax, yellow+(red*16)
            call SetTextColor
            call writeString

            mov  eax, white+(black*16)
            call SetTextColor
            call crlf
            call WaitMsg       ; wait till the user presses some key
            call clrscr
            call gameMenuScreen

        return_to_main:
            ; reset colors
            mov  eax, white+(black*16)
            call SetTextColor

            ret
gameMenuScreen endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstructionScreen PROC
    call clrscr

    ; top border 
    mov  eax, green+(black*16)
    call SetTextColor

    ; positioning the start point
    mov  dh, 2       ; row
    mov  dl, 10      ; col
    call gotoxy
    mov  edx, offset topBorder
    call WriteString

    ; side borders drawn on 6 rows starting from row 3 to row 5
    mov  ecx, 3
    drawSides:
        mov  dh, cl   ; row
        mov  dl, 10   ; col
        call gotoxy
        mov  edx, offset sideBorder
        call WriteString
        inc  cl
        cmp  cl, 6    
        jl   drawSides

    ; bottom border at row 6
    mov  dh, 6    ; row
    mov  dl, 10   ; col
    call gotoxy
    mov  edx, offset bottomBorder
    call WriteString

    ; instruction title
    mov  eax, yellow+(black*16)
    call SetTextColor
    mov  dh, 4
    mov  dl, 20
    call gotoxy
    mov  edx, offset instrTitle
    call WriteString

    ; instruction lines 
    mov  eax, yellow+(green*16)
    call SetTextColor

    mov  dh, 8
    mov  dl, 10
    call gotoxy
    mov  edx, offset instrLine1
    call WriteString

    mov  dh, 9
    mov  dl, 10
    call GotoXY
    mov  edx, offset instrLine2
    call WriteString

    mov  dh, 10
    mov  dl, 10
    call gotoxy
    mov  edx, offset instrLine3
    call WriteString

    mov  dh, 11
    mov  dl, 10
    call gotoxy
    mov  edx, offset instrLine4
    call WriteString

    mov  eax, yellow+(black*16)
    call SetTextColor
    mov  dh, 13
    mov  dl, 10
    call gotoxy
    mov  edx, offset instrPrompt
    call WriteString

    ; wait for 'r' key
    call ReadChar

    cmp al, 'r'
    je returnToMenu

    incorrectOption:
            call clrscr
            mov edx, offset invalidMsg
            mov  eax, yellow+(red*16)
            call SetTextColor
            call writeString

            mov  eax, white+(black*16)
            call SetTextColor
            call crlf
            call WaitMsg       ; wait till the user presses some key
            call clrscr
            call InstructionScreen

    ; reset to default colors
    mov  eax, white+(black*16)
    call SetTextColor

    ret
InstructionScreen endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; translating the 2D coordinates into a single 1D index with
; formula: current_row * total_columns + current_column

; setting the maze
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
        
        mov al, '.'   ; filling the maze with food
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    cmp al, '.'              ; checking if its food or not
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setBlocksSize proc

    ; 2 block in one row

    ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 7
    mov startY, 3
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 35
    mov startY, 3
    call draw_box

    ; 5 block in one row

    ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 4
    mov startY, 8
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 13
    mov startY, 8
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 22
    mov startY, 8
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 32
    mov startY, 8
    call draw_box
    
      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 4
    call RandomRange    ; 0 - 4
    add eax, 3          ; 3 - 7
    mov block_width, eax

    mov startX, 42
    mov startY, 8
    call draw_box

    ; 4 block in one row

    ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 5
    mov startY, 13
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 15
    mov startY, 13
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 28
    mov startY, 13
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 40
    mov startY, 13
    call draw_box

    ; 4 block in one row

    ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 3
    mov startY, 17
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 12
    mov startY, 17
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 2    
    call RandomRange    ; 0 - 2
    add eax, 2          ; 2 - 4 
    mov block_height, eax

    ; pick random width (min width of block will be 3)
    mov eax, 3
    call RandomRange    ; 0 - 3
    add eax, 3          ; 3 - 6
    mov block_width, eax

    mov startX, 30
    mov startY, 17
    call draw_box

      ; pick random height (min height of block will be 2)
    mov eax, 3    
    call RandomRange    ; 0 - 3
    add eax, 2          ; 2 - 5 
    mov block_height, eax

    ; pick random width (min width of block will be 5)
    mov eax, 6
    call RandomRange    ; 0 - 6
    add eax, 5          ; 5 - 11
    mov block_width, eax

    mov startX, 40
    mov startY, 17
    call draw_box
    
setBlocksSize endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drawmaze proc
    ; storing the values in stack
    push ecx
    push edx
    push ebx
    push esi
    push edi

    ; print the score and lives on top
    mov eax, yellow+(black*16)
    call setTextColor

    mov edx, offset score_txt
    mov ebx, edx
    mov dh, 4   ; row
    mov dl, 20   ; col
    call gotoxy
    mov edx, ebx
    call writeString

    mov dh, 4   ; row
    mov dl, 27   ; col
    call gotoxy
    mov eax, score
    call writeDec

    mov edx, offset lives_txt
    mov ebx, edx
    mov dh, 4   ; row
    mov dl, 64   ; col
    call gotoxy
    mov edx, ebx
    call writeString

    mov dh, 4   ; row
    mov dl, 72   ; col
    call gotoxy
    mov al, lives
    call writeDec

    ; resetting
    mov eax, white+(black*16)
    call setTextColor

    mov ecx, 0      ; starting row 
    nextrow:
        ; calculating index using esi because edx will be used by gotoxy
        mov esi, offset maze
        mov eax, ecx
        imul eax, cols+1
        add esi, eax       

        ; storing the x and y positions for positioning cursor using gotoxy
        mov dh, cl         ; current row
        add dh, row_start_point         ; storing row start point  
        mov dl, col_start_point         ; storing col start point
        call gotoxy

        ;mov edi, ebx
       ; call writestring    ; writing whole string (single row) till null terminator
        
        mov ebx, cols + 1    ; get total columns
        colLoop:
            mov al, [esi]    ; get the character at the index  

            ; color based on character
            cmp al, '#'
            je wall
            cmp al, '*'
            je block
            cmp al, '.'
            je food
            cmp al, 'P'
            je pacman
            cmp al, '@'   ; red ghost level 1
            je redGhost
            cmp al, '%'   ; pinky level 2
            je pinkGhost
            cmp al, '$'   ; clyde level 3
            je cyanGhost
            cmp al, '&'   ; inky level 3
            je blueGhost

            ; else case
            mov eax, white+(black*16)
            jmp colorDone

            wall:
            ; making the wall solid
            mov eax, green+(green*16)
            jmp colorDone

            block:
            ; making the block solid
            mov eax, green+(green*16)
            jmp colorDone

            food:
            mov eax, green+(black*16)
            jmp colorDone

            pacman:
            mov eax, yellow+(black*16)
            jmp colorDone

            redGhost:
            mov eax, red+(black*16)
            jmp colorDone

            pinkGhost:
            mov eax, magenta+(black*16)
            jmp colorDone

            cyanGhost:
            mov eax, cyan+(black*16)
            jmp colorDone

            blueGhost:
            mov eax, blue+(black*16)
            jmp colorDone

            colorDone:
            call SetTextColor

            ; print that single char
            mov al, [esi]
            call WriteChar

            inc esi   ; next character
            inc dl    ; next position in the col
            dec ebx   ; decrement total col left
            jnz colLoop

        inc ecx               ; increment row 
        cmp ecx, rows         ; see if all rows are completed or not
        jl nextrow            ; if not loop again till all rows are completed
    
    ; restore the original values
    pop edi
    pop esi
    pop ebx
    pop edx
    pop ecx
    ret
drawmaze endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pacman_movement proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; ah contains the scan code for arrow keys (0x48 up, 0x50 down, 0x4b left, 0x4d right)
    mov al, ah           ; move scan code into al

    ; load old position
    mov ebx, pacmanx    ; ebx = old x
    mov ecx, pacmany    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    ; adjust newx/newy based on arrow pressed
    cmp al, 4dh        ; right arrow
    je move_right
    cmp al, 4bh        ; left arrow
    je move_left
    cmp al, 48h       ; up arrow
    je move_up
    cmp al, 50h       ; down arrow
    je move_down
    jmp done           ; not an arrow key no move

    move_right:
        inc edx    ; move right
        jmp checkcell
    move_left:  
        dec edx    ; move left
        jmp checkcell
    move_up:    
        dec esi    ; move up
        jmp checkcell
    move_down:  
        inc esi    ; move down

    checkcell:
        ; getting the new 1D index
        mov eax, esi             ; new row
        imul eax, cols+1
        add eax, edx             ; new col
        mov edi, offset maze
        add edi, eax

        mov al, [edi]      ; getting the value at index
        cmp al, '#'        ; wall
        je done
        cmp al, '*'        ; block
        je done
        cmp al, '.'        ; food
        jne movethere

        mov byte ptr [edi], ' '   ; clear the food

        mov temp, edx      ; preserving edx first
        ; write the new score
        mov dh, 4   ; row
        mov dl, 27   ; col
        call gotoxy

        ;if food, eat it and increment score
        inc score
        mov eax, score
        call writeDec

        mov edx, temp             ;  restoring 

    movethere:
        ; Erase old P 
        mov eax, ecx              ; old row
        imul eax, cols+1
        add eax, ebx              ; old col
        mov edi, offset maze
        add edi, eax

        mov temp, edx                  ; preserving edx first
        mov byte ptr [edi], ' '        ; updating the maze
        mov dh, cl                     ; maze old row 
        add dh, row_start_point        ; adding the start point to get accurate X
        mov dl, bl                     ; maze old col
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, ' '
        call writechar
        mov edx, temp                  ;  restoring 

        ; Draw new P on screen
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov ax, si                     ; new row
        mov dh, al                     ; new maze row
        add dh, row_start_point        ; adding the start point to get accurate X
        ; dl already has the new col 
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, 'P'
        call writechar
        mov edx, temp                  ;  restoring 

        ; Update variables
        mov pacmanx, edx
        mov pacmany, esi

    done:
        ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    ret
pacman_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end main
