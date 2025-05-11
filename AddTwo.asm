; Ramalah Amir (23i-2644) DS-4C

include irvine32.inc

; keeping the maze size constant for all levels
rows = 21
cols = 55
row_start_point = 6
col_start_point = 20
block_char  = '*'
bonusFood_char = '+'

BUFFER_SIZE = 50

.data
    ; reserving memory for maze in the memory
    ; +1 is for the null terminator at the end of each row for writeString
    maze byte rows * (cols + 1) dup(' ')   

    ; a boolean array to keep track of food eaten or not
    ; this is to help with the ghost movement
    eaten byte rows*cols dup(0)  
    ; temp var
    eaten_bool byte 0

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
    userName    byte BUFFER_SIZE dup(0)       
    topBorder   byte "+======================================+",0
    sideBorder  byte "|                                      |",0
    bottomBorder byte "+======================================+",0

    filename      byte "playerNames.txt",0
    fileHandle    handle ?
    bytesWritten  dword ?
    nextLine      byte 13,10      ; clrf

    ; game menue screen
    menuTitle    byte "   GAME MENU   ", 0
    opt1         byte "1. Start Game", 0
    opt3         byte "2. Instructions", 0
    opt4         byte "3. Exit", 0
    select_optionMsg    byte "Select option (1-4): ", 0

    ; for main game screen
    score_txt byte "SCORE: ", 0
    lives_txt byte "LIVES: ", 0
    score dword 0
    lives dword 3
    collision_bool byte 0

    ; msgs
    exitGameBool byte 0
    exittingMsg byte "Exiting Game...... :)", 0
    invalidMsg byte "Invalid Option entered, Try Again..... :(", 0
    youLoseMsg byte "You lost the game :(", 0
    PauseMsg byte "Game Paused....", 0
    HidePauseMsg byte "Game Paused....Press any key to continue.......", 0
    nameAndScoreMsg byte "NAME and SCORE", 0

    ; instruction screen
    instrTitle byte "   INSTRUCTIONS   ", 0
    instrLine1 byte "Use arrow keys to move Pac-Man", 0
    instrLine2 byte "Collect all dots (.) to win", 0
    instrLine3 byte "Avoid ghosts (@ % & $)", 0
    instrLine4 byte "Press Q anytime to quit", 0
    instrPrompt byte 0Dh,0Ah, "Press 'r' to return...",0

    ; making a temp variable
    temp dword 0
    ; stores the current moving direction
    movement_var byte 'R'

    ; ghosts
    ; level 1 ghost Red
    red_X dword 0
    red_Y dword 0
    ; level 2 ghost pinky
    pinky_X dword 0
    pinky_Y dword 0
    ; level 3 ghost clyde, inky
    clyde_X dword 0
    clyde_Y dword 0
    inky_X dword 0
    inky_Y dword 0

    ; level number
    level byte 3

    ; for level 2
    bonusFoodCount dword 10

.code
main proc
    call randomize     ; Re-seeds the random number generator

    ; calling screens
    call welcomeScreen
    call gameMenuScreen

    call clrscr

    ; building the game main screen
    call buildmaze
    call setBlocksSize
    call place_pacman

    mov al, level
    cmp al, 1
    je level1
    cmp al, 2
    je level2

    level3:                                ; for level 3 display all ghosts
        call place_levelThree_ghost
    level2:                                ; level 2 will also have level 1's ghost
        call place_leveltwo_ghost
        call placeBonusFood
    level1:
        call place_levelOne_ghost 
    
    call drawmaze

    game_loop:

      ; everytime check for lives
      mov eax, lives
      cmp eax, 0
      je you_lose

      ; check for key press
      ; If ZF=1, no key was pressed
      call ReadKey   
      jz no_input

      cmp al, 'q'       ; quit game
      je  exit_game

      cmp al, 'p'
      je call_pause

      ; if any key was pressed
     
      cmp ah, 4dh        ; right arrow
      je set_right
      cmp ah, 4bh        ; left arrow
      je set_left
      cmp ah, 48h       ; up arrow
      je set_up
      cmp ah, 50h       ; down arrow
      je set_down

      ; if neither of the above was pressed
      jmp no_input

      set_right:
        mov movement_var, 'R'
        jmp move
      set_left:
        mov movement_var, 'L'
        jmp move
      set_up:
        mov movement_var, 'U'
        jmp move
      set_down:
        mov movement_var, 'D'
        jmp move

      move: 
        call pacman_movement

        mov al, level
        cmp al, 1
        je level1_move
        cmp al, 2
        je level2_move

        level3_move:   
            call inky_ghost_movement
            call clyde_ghost_movement
        level2_move:
            call pinky_ghost_movement
        level1_move:
            call red_ghost_movement
      jmp game_loop
    
    no_input:
        ; no new key, continue in stored direction
        mov ah, 0        ; dummy so no new direction is set
        call pacman_movement

        mov al, level
        cmp al, 1
        je level1_no_input
        cmp al, 2
        je level2_no_input

        level3_no_input:   
            call inky_ghost_movement
            call clyde_ghost_movement
        level2_no_input:
            call pinky_ghost_movement
        level1_no_input:
            call red_ghost_movement
               
        ; for speed
        mov al, level
        cmp al, 1
        je level1_speed
        cmp al, 2
        je level2_speed 

        level3_speed:
            mov  eax, 80    ;delay 80 milliseconds
            call Delay
            jmp game_loop
        level2_speed:
            mov  eax, 120   ;delay 120 milliseconds
            call Delay
            jmp game_loop
        level1_speed:
            mov  eax, 200   ;delay 200 milliseconds
            call Delay
            jmp game_loop

    ; global label
    cmp exitGameBool, 1    ; if exit is triggered only then displey the exitMsg
    jne finish

    call_pause:
        ; write messege on top of the screen
        mov dh, 0
        mov dl, 0
        call gotoxy
     
        mov  edx, offset PauseMsg
        mov  eax, green+(yellow*16)
        call SetTextColor
        call writeString
        call waitMsg

        ; after waiting hide the message
        mov dh, 0
        mov dl, 0
        call gotoxy
        mov  edx, offset HidePauseMsg
        mov  eax, black+(black*16)
        call SetTextColor
        call writeString

        ;reset the color and go back to the game
        mov  eax, white+(black*16)
        call SetTextColor
        jmp game_loop

    you_lose: 
        call clrscr
        mov  edx, offset youLoseMsg
        mov  eax, green+(yellow*16)
        call SetTextColor
        call writeString
        call waitMsg
        mov  eax, white+(black*16)
        call SetTextColor

    exit_game:: 
        call clrscr
        mov  edx, offset exittingMsg
        mov  eax, green+(yellow*16)
        call SetTextColor
        call writeString

        call waitMsg

        mov  eax, white+(black*16)
        call SetTextColor
        call displayNameandScore_screen

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

    ; writing the playerName into the file
    mov edx, offset filename
    call CreateOutputFile        ; this clears the file
    mov fileHandle, eax

    ; write new user name
    mov eax, fileHandle
    mov edx, offset userName
    mov ecx, lengthof userName
    call WriteToFile

    mov edx, offset nextLine
    mov ecx, lengthof nextLine
    call WriteToFile

    call  CloseFile
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
        mov  edx, offset opt3
        call WriteString

        mov  dh, 10
        mov  dl, 22
        call gotoxy
        mov  edx, offset opt4
        call WriteString

        ; select option msg
        mov  eax, yellow+(black*16)
        call SetTextColor
        mov  dh, 12
        mov  dl, 20
        call gotoxy
        mov  edx, offset select_optionMsg
        call WriteString

        ; read a single key  
        call ReadChar        ; stored in eax

        cmp al, '1'
        je return_to_main
        cmp al, '2'
        je instructions
        cmp al, '3'
        je exit_game
        jmp incorrectOption

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

displayNameandScore_screen proc
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

    ; side borders drawn on 6 rows starting from row 3 to row 6
    mov  ecx, 3
    drawSides:
        mov  dh, cl   ; row
        mov  dl, 10   ; col
        call gotoxy
        mov  edx, offset sideBorder
        call WriteString
        inc  cl
        cmp  cl, 7    
        jl   drawSides

    ; title
    mov  eax, yellow+(green*16)
    call SetTextColor
    mov  dh, 4
    mov  dl, 22
    call gotoxy
    mov  edx, offset nameAndScoreMsg
    call WriteString

    mov  eax, yellow+(black*16)
    call SetTextColor
    mov  dh, 5
    mov  dl, 22
    call gotoxy
    mov  edx, offset userName
    call WriteString

    mov  eax, yellow+(black*16)
    call SetTextColor
    mov  dh, 5
    mov  dl, 30
    call gotoxy
    mov  edx, offset score
    call WriteDec
    
    ; bottom border at row 6
    mov  dh, 7    ; row
    mov  dl, 10   ; col
    call gotoxy
    mov  edx, offset bottomBorder
    mov  eax, green+(black*16)
    call SetTextColor
    call WriteString
    call crlf
    
displayNameandScore_screen endp

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

place_levelOne_ghost proc
    ; preserving the old value
    push edi

    find_random_indexes:
        ; making the starting position random for red
        mov eax, rows - 2     ; getting random from 0 - 19
        call RandomRange      ; gives 0 - 18
        inc eax               ; gives 0 - 19
        mov red_Y, eax      ; setting the row value for red

        mov eax, cols - 2     ; getting random from 0 - 48
        call RandomRange      ; gives 0 - 47
        inc eax               ; gives 0 - 48
        mov red_X, eax      ; setting the column value for red
    
    ; checking if the new position is empty or not to prevent overwriting

    ; calculating the 1d equivalent index in the maze
    mov  edi, offset maze 
    mov  eax, red_Y
    imul eax, cols + 1     
    add  eax, red_X     
    add  edi, eax       

    mov al, byte ptr [edi]   ; loading whatever’s already in that position
    cmp al, '.'              ; checking if its food or not
    jne  try_again           ; if not find new position for red

    mov byte ptr [edi], '@'  ; if its empty, place red here
    jmp done_placing

    try_again:
        ; jump back up to pick new random indexes
        jmp find_random_indexes

    done_placing:
        pop edi
    ret
place_levelOne_ghost endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

place_levelTwo_ghost proc
    ; preserving the old value
    push edi

    find_random_indexes:
        ; making the starting position random for pinky
        mov eax, rows - 2     ; getting random from 0 - 19
        call RandomRange      ; gives 0 - 18
        inc eax               ; gives 0 - 19
        mov pinky_Y, eax      ; setting the row value for pinky

        mov eax, cols - 2     ; getting random from 0 - 48
        call RandomRange      ; gives 0 - 47
        inc eax               ; gives 0 - 48
        mov pinky_X, eax      ; setting the column value for pinky
    
    ; checking if the new position is empty or not to prevent overwriting

    ; calculating the 1d equivalent index in the maze
    mov  edi, offset maze 
    mov  eax, pinky_Y
    imul eax, cols + 1     
    add  eax, pinky_X     
    add  edi, eax       

    mov al, byte ptr [edi]   ; loading whatever’s already in that position
    cmp al, '.'              ; checking if its food or not
    jne  try_again           ; if not find new position for pinky

    mov byte ptr [edi], '%'  ; if its empty, place pinky here
    jmp done_placing

    try_again:
        ; jump back up to pick new random indexes
        jmp find_random_indexes

    done_placing:
        pop edi
    ret
place_levelTwo_ghost endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

place_levelThree_ghost proc
    ; preserving the old value
    push edi

    find_random_indexes_for_clyde:
        ; making the starting position random for clyde
        mov eax, rows - 2     ; getting random from 0 - 19
        call RandomRange      ; gives 0 - 18
        inc eax               ; gives 0 - 19
        mov clyde_Y, eax      ; setting the row value for clyde

        mov eax, cols - 2     ; getting random from 0 - 48
        call RandomRange      ; gives 0 - 47
        inc eax               ; gives 0 - 48
        mov clyde_X, eax      ; setting the column value for clyde
    
    ; checking if the new position is empty or not to prevent overwriting

    ; calculating the 1d equivalent index in the maze
    mov  edi, offset maze 
    mov  eax, clyde_Y
    imul eax, cols + 1     
    add  eax, clyde_X     
    add  edi, eax       

    mov al, byte ptr [edi]   ; loading whatever’s already in that position
    cmp al, '.'              ; checking if its food or not
    jne  try_again_for_clyde           ; if not find new position for clyde

    mov byte ptr [edi], '$'  ; if its empty, place clyde here
    jmp find_random_indexes_for_inky

    try_again_for_clyde:
        ; jump back up to pick new random indexes
        jmp find_random_indexes_for_clyde

    find_random_indexes_for_inky:
        ; making the starting position random for inky
        mov eax, rows - 2     ; getting random from 0 - 19
        call RandomRange      ; gives 0 - 18
        inc eax               ; gives 0 - 19
        mov inky_Y, eax      ; setting the row value for inky

        mov eax, cols - 2     ; getting random from 0 - 48
        call RandomRange      ; gives 0 - 47
        inc eax               ; gives 0 - 48
        mov inky_X, eax      ; setting the column value for inky
    
    ; checking if the new position is empty or not to prevent overwriting

    ; calculating the 1d equivalent index in the maze
    mov  edi, offset maze 
    mov  eax, inky_Y
    imul eax, cols + 1     
    add  eax, inky_X     
    add  edi, eax       

    mov al, byte ptr [edi]   ; loading whatever’s already in that position
    cmp al, '.'              ; checking if its food or not
    jne  try_again_for_inky           ; if not find new position for inky

    mov byte ptr [edi], '&'  ; if its empty, place inky here
    jmp done_placing

    try_again_for_inky:
        ; jump back up to pick new random indexes
        jmp find_random_indexes_for_inky

    done_placing:
        pop edi
    ret
place_levelThree_ghost endp

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

    mov al, level
    cmp al, 1
    je level1_obstacles
    cmp al, 2
    je level2_obstacles
    
    ; for level 3 all obstacles

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

     level2_obstacles: 
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

    level1_obstacles: 
        ; 2 block in one row for level 1

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

    done: 
        ret 
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
    mov eax, lives
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
            je clydeGhost
            cmp al, '&'   ; inky level 3
            je inkyGhost

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
            mov eax, lightMagenta+(black*16)
            jmp colorDone

            clydeGhost:
            mov eax, lightBlue+(black*16)
            jmp colorDone

            inkyGhost:
            mov eax, lightGray+(black*16)
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

    ; setting for score and P
    mov  eax, yellow+(black*16)
    call SetTextColor

    ; load old position
    mov ebx, pacmanx    ; ebx = old x
    mov ecx, pacmany    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    cmp movement_var, 'R'
    je move_right
    cmp movement_var, 'L'
    je move_left
    cmp movement_var, 'U'
    je move_up
    cmp movement_var, 'D'
    je move_down

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
        je food
        cmp al, '+'        ; bonus food
        je bonusFood

        food: 
            mov byte ptr [edi], ' '   ; clear the food

            ; for the boolean array
            mov eax, esi             ; new row
            imul eax, cols
            add eax, edx             ; new col
            mov edi, offset eaten
            add edi, eax
            mov byte ptr [edi], 1   ; clear the food

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
            jmp movethere
    
    bonusFood: 
            mov byte ptr [edi], ' '   ; clear the bonus food

            ; for the boolean array
            mov eax, esi             ; new row
            imul eax, cols
            add eax, edx             ; new col
            mov edi, offset eaten
            add edi, eax
            mov byte ptr [edi], 1   ; clear the bonusfood

            mov temp, edx      ; preserving edx first
            ; write the new score
            mov dh, 4   ; row
            mov dl, 27   ; col
            call gotoxy

            ;if food, eat it and increment score
            add score, 5     ; increment score by 5 points
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
        mov eax, esi              ; new row
        imul eax, cols+1
        add eax, edx              ; new col
        mov edi, offset maze
        add edi, eax
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov byte ptr [edi], 'P'        ; updating the maze

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
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    ret
pacman_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

red_ghost_movement proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; setting color for RED
    mov  eax, red+(black*16)
    call SetTextColor

    ; load old RED position
    mov ebx, red_X    ; ebx = old x
    mov ecx, red_Y    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    try_again:
        ; pick random movement
        mov eax, 100
        call  RandomRange    ; 0 - 100
        ; maping that to a direction:
        cmp eax, 25
        jl try_right
        cmp eax, 50
        jl try_left
        cmp eax, 75
        jl try_up
        ; else move down

    try_down:
        inc esi
        jmp checkcell

    try_up:
        dec esi
        jmp checkcell

    try_left:
        dec edx
        jmp checkcell

    try_right:
        inc edx

    checkcell:
        ; boundary check
        cmp esi, 1
        jl  try_again
        cmp esi, rows-2
        jg  try_again
        cmp edx, 1
        jl  try_again
        cmp edx, cols-2
        jg  try_again
        
        ; getting the new 1D index
        mov eax, esi             ; new row
        imul eax, cols+1
        add eax, edx             ; new col
        mov edi, offset maze
        add edi, eax

        mov al, byte ptr [edi]      ; getting the value at index
        cmp al, '*'        ; block
        je try_again
        ; if its any other ghost as well
        cmp al, '%'       
        je try_again
        cmp al, '&'       
        je try_again
        cmp al, '$'       
        je try_again

        ; collision with pacman
        mov   eax, edx       ; check the new col
        cmp   eax, pacmanx
        jne   movethere      ; if no match then continue ghost movement
        mov   eax, esi       ; check the new row
        cmp   eax, pacmany       
        je collision_detected  ; if both equal then go to collision detection

    movethere:
        ; Erase old Ghost
        mov temp, edx                  ; preserving edx

        ; determine what to restore at old position
        mov eax, ecx
        imul eax, cols
        add eax, ebx
        mov edi, offset eaten
        add edi, eax
        mov al, [edi]
        cmp al, 1
        je restore_space

        ; else food:
        mov eax, ecx
        imul eax, cols+1
        add eax, ebx
        mov edi, offset maze
        add edi, eax
        mov byte ptr [edi], '.' 

        ; set color for food
        mov  eax, green+(black*16)
        call SetTextColor

        mov dh, cl                     ; maze old row 
        add dh, row_start_point        ; adding the start point to get accurate X
        mov dl, bl                     ; maze old col
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '.'
        call writechar

        ; reset color for ghost
        mov  eax, red+(black*16)
        call SetTextColor
        jmp restored

        restore_space:
            mov eax, ecx
            imul eax, cols+1
            add eax, ebx
            mov edi, offset maze
            add edi, eax
            mov byte ptr [edi], ' '

            mov dh, cl                     ; maze old row 
            add dh, row_start_point        ; adding the start point to get accurate X
            mov dl, bl                     ; maze old col
            add dl, col_start_point        ; adding the start point to get accurate Y
            call gotoxy
            mov al, ' '
            call writechar

        restored:
                mov edx, temp                  ;  restoring 

        ; Draw new ghost on screen
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov ax, si                     ; new row
        mov dh, al                     ; new maze row
        add dh, row_start_point        ; adding the start point to get accurate X
        ; dl already has the new col 
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '@'
        call writechar
        mov edx, temp                  ;  restoring 

        ; Update variables
        mov red_X, edx
        mov red_Y, esi
        jmp done
    
    collision_detected:
        mov byte ptr [edi], ' '   ; clear the pacman in the maze
        ; now clearing on the screen
        mov eax, pacmany               ; old row
        mov dh, al                     
        add dh, row_start_point        ; adding the start point to get accurate X
        mov eax, pacmanx               ; old col
        mov dl, al                     
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, ' '
        call writechar

        ; Update variables
        mov pacmanx, 1
        mov pacmany, 1

        mov  eax, yellow+(black*16)
        call SetTextColor

        ; write the new pacman
        mov eax, pacmany
        imul eax, cols+1
        add eax, pacmanx
        mov edi, offset maze
        add edi, eax
        mov byte ptr [edi], 'P'         ; updating the maze

        mov eax, pacmany               ; new row
        mov dh, al                     
        add dh, row_start_point        ; adding the start point to get accurate X
        mov eax, pacmanx               ; new col
        mov dl, al                     
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, 'P'
        call writechar

        ;decrement the lives 
        dec lives
        mov eax, lives
        ; writing the updated lives
        mov dh, 4   ; row
        mov dl, 72   ; col
        call gotoxy
        call writedec
        
    done:
        ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    
    ret
red_ghost_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pinky_ghost_movement proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; setting color for pinky
    mov  eax, lightMagenta+(black*16)
    call SetTextColor

    ; load old pinky position
    mov ebx, pinky_X    ; ebx = old x
    mov ecx, pinky_Y    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    try_again:
        ; pick random movement
        mov eax, 100
        call  RandomRange    ; 0 - 100
        ; maping that to a direction:
        cmp eax, 25
        jl try_right
        cmp eax, 50
        jl try_left
        cmp eax, 75
        jl try_up
        ; else move down

    try_down:
        inc esi
        jmp checkcell

    try_up:
        dec esi
        jmp checkcell

    try_left:
        dec edx
        jmp checkcell

    try_right:
        inc edx

    checkcell:
        ; boundary check
        cmp esi, 1
        jl  try_again
        cmp esi, rows-2
        jg  try_again
        cmp edx, 1
        jl  try_again
        cmp edx, cols-2
        jg  try_again
        
        ; getting the new 1D index
        mov eax, esi             ; new row
        imul eax, cols+1
        add eax, edx             ; new col
        mov edi, offset maze
        add edi, eax

        mov al, byte ptr [edi]      ; getting the value at index
        cmp al, '*'        ; block
        je try_again
        ; if its any other ghost as well
        cmp al, '@'       
        je try_again
        cmp al, '&'       
        je try_again
        cmp al, '$'       
        je try_again

        ; collision with pacman
       ; mov   eax, edx       ; check the new col
       ; cmp   eax, pacmanx
       ; jne   movethere      ; if no match then continue ghost movement
       ; mov   eax, esi       ; check the new row
       ; cmp   eax, pacmany       
       ; je collision_detected  ; if both equal then go to collision detection

    movethere:
        ; Erase old Ghost
        mov temp, edx                  ; preserving edx

        ; determine what to restore at old position
        mov eax, ecx
        imul eax, cols
        add eax, ebx
        mov edi, offset eaten
        add edi, eax
        mov al, [edi]
        cmp al, 1
        je restore_space

        ; else food:
        mov eax, ecx
        imul eax, cols+1
        add eax, ebx
        mov edi, offset maze
        add edi, eax
        mov byte ptr [edi], '.' 

        ; set color for food
        mov  eax, green+(black*16)
        call SetTextColor

        mov dh, cl                     ; maze old row 
        add dh, row_start_point        ; adding the start point to get accurate X
        mov dl, bl                     ; maze old col
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '.'
        call writechar

        ; reset color for ghost
        mov  eax, lightMagenta+(black*16)
        call SetTextColor
        jmp restored

        restore_space:
            mov eax, ecx
            imul eax, cols+1
            add eax, ebx
            mov edi, offset maze
            add edi, eax
            mov byte ptr [edi], ' '

            mov dh, cl                     ; maze old row 
            add dh, row_start_point        ; adding the start point to get accurate X
            mov dl, bl                     ; maze old col
            add dl, col_start_point        ; adding the start point to get accurate Y
            call gotoxy
            mov al, ' '
            call writechar

        restored:
                mov edx, temp                  ;  restoring 

        ; Draw new ghost on screen
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov ax, si                     ; new row
        mov dh, al                     ; new maze row
        add dh, row_start_point        ; adding the start point to get accurate X
        ; dl already has the new col 
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '%'
        call writechar
        mov edx, temp                  ;  restoring 

        ; Update variables
        mov pinky_X, edx
        mov pinky_Y, esi
    
   ; collision_detected:
   ;     mov byte ptr [edi], ' '   ; clear the pacman in the maze
   ;     ; now clearing on the screen
   ;     mov eax, pacmany               ; old row
   ;     mov dh, al                     
   ;    add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; old col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, ' '
   ;     call writechar

   ;     ; Update variables
   ;     mov pacmanx, 1
   ;     mov pacmany, 1

   ;     mov  eax, yellow+(black*16)
   ;     call SetTextColor

   ;     ; write the new pacman
   ;     mov eax, pacmany
   ;     imul eax, cols+1
   ;     add eax, pacmanx
   ;     mov edi, offset maze
   ;     add edi, eax
   ;     mov byte ptr [edi], 'P'         ; updating the maze

   ;     mov eax, pacmany               ; new row
   ;     mov dh, al                     
   ;     add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; new col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, 'P'
   ;     call writechar

   ;     ;decrement the lives 
   ;     dec lives
   ;     mov eax, lives
   ;     ; writing the updated lives
   ;     mov dh, 4   ; row
   ;     mov dl, 72   ; col
   ;     call gotoxy
   ;     call writedec

    done:
        ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    ret
pinky_ghost_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clyde_ghost_movement proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; setting color for clyde
    mov  eax, lightBlue+(black*16)
    call SetTextColor

    ; load old clyde position
    mov ebx, clyde_X    ; ebx = old x
    mov ecx, clyde_Y    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    try_again:
        ; pick random movement
        mov eax, 100
        call  RandomRange    ; 0 - 100
        ; maping that to a direction:
        cmp eax, 25
        jl try_right
        cmp eax, 50
        jl try_left
        cmp eax, 75
        jl try_up
        ; else move down

    try_down:
        inc esi
        jmp checkcell

    try_up:
        dec esi
        jmp checkcell

    try_left:
        dec edx
        jmp checkcell

    try_right:
        inc edx

    checkcell:
        ; boundary check
        cmp esi, 1
        jl  try_again
        cmp esi, rows-2
        jg  try_again
        cmp edx, 1
        jl  try_again
        cmp edx, cols-2
        jg  try_again
        
        ; getting the new 1D index
        mov eax, esi             ; new row
        imul eax, cols+1
        add eax, edx             ; new col
        mov edi, offset maze
        add edi, eax

        mov al, byte ptr [edi]      ; getting the value at index
        cmp al, '*'        ; block
        je try_again
        ; if its any other ghost as well
        cmp al, '@'       
        je try_again
        cmp al, '&'       
        je try_again
        cmp al, '%'       
        je try_again

    ;    ; collision with pacman
    ;    mov   eax, edx       ; check the new col
    ;    cmp   eax, pacmanx
    ;    jne   movethere      ; if no match then continue ghost movement
    ;    mov   eax, esi       ; check the new row
    ;    cmp   eax, pacmany       
    ;    je collision_detected  ; if both equal then go to collision detection

    movethere:
        ; Erase old Ghost
        mov temp, edx                  ; preserving edx

        ; determine what to restore at old position
        mov eax, ecx
        imul eax, cols
        add eax, ebx
        mov edi, offset eaten
        add edi, eax
        mov al, [edi]
        cmp al, 1
        je restore_space

        ; else food:
        mov eax, ecx
        imul eax, cols+1
        add eax, ebx
        mov edi, offset maze
        add edi, eax
        mov byte ptr [edi], '.' 

        ; set color for food
        mov  eax, green+(black*16)
        call SetTextColor

        mov dh, cl                     ; maze old row 
        add dh, row_start_point        ; adding the start point to get accurate X
        mov dl, bl                     ; maze old col
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '.'
        call writechar

        ; reset color for ghost
        mov  eax, lightBlue+(black*16)
        call SetTextColor
        jmp restored

        restore_space:
            mov eax, ecx
            imul eax, cols+1
            add eax, ebx
            mov edi, offset maze
            add edi, eax
            mov byte ptr [edi], ' '

            mov dh, cl                     ; maze old row 
            add dh, row_start_point        ; adding the start point to get accurate X
            mov dl, bl                     ; maze old col
            add dl, col_start_point        ; adding the start point to get accurate Y
            call gotoxy
            mov al, ' '
            call writechar

        restored:
                mov edx, temp                  ;  restoring 

        ; Draw new ghost on screen
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov ax, si                     ; new row
        mov dh, al                     ; new maze row
        add dh, row_start_point        ; adding the start point to get accurate X
        ; dl already has the new col 
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '$'
        call writechar
        mov edx, temp                  ;  restoring 

        ; Update variables
        mov clyde_X, edx
        mov clyde_Y, esi
    
   ; collision_detected:
   ;     mov byte ptr [edi], ' '   ; clear the pacman in the maze
   ;     ; now clearing on the screen
   ;     mov eax, pacmany               ; old row
   ;     mov dh, al                     
   ;     add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; old col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, ' '
   ;     call writechar

   ;     ; Update variables
   ;     mov pacmanx, 1
   ;     mov pacmany, 1

   ;     mov  eax, yellow+(black*16)
   ;     call SetTextColor

        ; write the new pacman
   ;     mov eax, pacmany
   ;     imul eax, cols+1
   ;     add eax, pacmanx
   ;     mov edi, offset maze
   ;     add edi, eax
   ;     mov byte ptr [edi], 'P'         ; updating the maze

   ;     mov eax, pacmany               ; new row
   ;     mov dh, al                     
   ;     add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; new col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, 'P'
   ;     call writechar

   ;     ;decrement the lives 
   ;     dec lives
   ;     mov eax, lives
   ;     ; writing the updated lives
   ;     mov dh, 4   ; row
   ;     mov dl, 72   ; col
   ;     call gotoxy
   ;     call writedec

    done:
        ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    ret
clyde_ghost_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inky_ghost_movement proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; setting color for inky
    mov  eax, lightGray+(black*16)
    call SetTextColor

    ; load old inky position
    mov ebx, inky_X    ; ebx = old x
    mov ecx, inky_Y    ; ecx = old y

    ; start with newx = oldx, newy = oldy
    mov edx, ebx        ; edx = newx
    mov esi, ecx        ; esi = newy

    try_again:
        ; pick random movement
        mov eax, 100
        call  RandomRange    ; 0 - 100
        ; maping that to a direction:
        cmp eax, 25
        jl try_right
        cmp eax, 50
        jl try_left
        cmp eax, 75
        jl try_up
        ; else move down

    try_down:
        inc esi
        jmp checkcell

    try_up:
        dec esi
        jmp checkcell

    try_left:
        dec edx
        jmp checkcell

    try_right:
        inc edx

    checkcell:
        ; boundary check
        cmp esi, 1
        jl  try_again
        cmp esi, rows-2
        jg  try_again
        cmp edx, 1
        jl  try_again
        cmp edx, cols-2
        jg  try_again
        
        ; getting the new 1D index
        mov eax, esi             ; new row
        imul eax, cols+1
        add eax, edx             ; new col
        mov edi, offset maze
        add edi, eax

        mov al, byte ptr [edi]      ; getting the value at index
        cmp al, '*'        ; block
        je try_again
        ; if its any other ghost as well
        cmp al, '@'       
        je try_again
        cmp al, '%'       
        je try_again
        cmp al, '$'       
        je try_again

    ;    ; collision with pacman
    ;    mov   eax, edx       ; check the new col
    ;    cmp   eax, pacmanx
    ;    jne   movethere      ; if no match then continue ghost movement
    ;    mov   eax, esi       ; check the new row
    ;    cmp   eax, pacmany       
    ;    je collision_detected  ; if both equal then go to collision detection

    movethere:
        ; Erase old Ghost
        mov temp, edx                  ; preserving edx

        ; determine what to restore at old position
        mov eax, ecx
        imul eax, cols
        add eax, ebx
        mov edi, offset eaten
        add edi, eax
        mov al, [edi]
        cmp al, 1
        je restore_space

        ; else food:
        mov eax, ecx
        imul eax, cols+1
        add eax, ebx
        mov edi, offset maze
        add edi, eax
        mov byte ptr [edi], '.' 

        ; set color for food
        mov  eax, green+(black*16)
        call SetTextColor

        mov dh, cl                     ; maze old row 
        add dh, row_start_point        ; adding the start point to get accurate X
        mov dl, bl                     ; maze old col
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '.'
        call writechar

        ; reset color for ghost
        mov  eax, lightGray+(black*16)
        call SetTextColor
        jmp restored

        restore_space:
            mov eax, ecx
            imul eax, cols+1
            add eax, ebx
            mov edi, offset maze
            add edi, eax
            mov byte ptr [edi], ' '

            mov dh, cl                     ; maze old row 
            add dh, row_start_point        ; adding the start point to get accurate X
            mov dl, bl                     ; maze old col
            add dl, col_start_point        ; adding the start point to get accurate Y
            call gotoxy
            mov al, ' '
            call writechar

        restored:
                mov edx, temp                  ;  restoring 

        ; Draw new ghost on screen
        ; set cursor to new coords 
        mov temp, edx                  ; preserving edx first
        mov ax, si                     ; new row
        mov dh, al                     ; new maze row
        add dh, row_start_point        ; adding the start point to get accurate X
        ; dl already has the new col 
        add dl, col_start_point        ; adding the start point to get accurate Y
        call gotoxy
        mov al, '&'
        call writechar
        mov edx, temp                  ;  restoring 

        ; Update variables
        mov inky_X, edx
        mov inky_Y, esi

   ; collision_detected:
   ;     mov byte ptr [edi], ' '   ; clear the pacman in the maze
   ;     ; now clearing on the screen
   ;     mov eax, pacmany               ; old row
   ;     mov dh, al                     
   ;     add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; old col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, ' '
   ;     call writechar

   ;    ; Update variables
   ;     mov pacmanx, 1
   ;     mov pacmany, 1

   ;     mov  eax, yellow+(black*16)
   ;     call SetTextColor

   ;     ; write the new pacman
   ;     mov eax, pacmany
   ;     imul eax, cols+1
   ;     add eax, pacmanx
   ;     mov edi, offset maze
   ;     add edi, eax
   ;     mov byte ptr [edi], 'P'         ; updating the maze

   ;     mov eax, pacmany               ; new row
   ;     mov dh, al                     
   ;     add dh, row_start_point        ; adding the start point to get accurate X
   ;     mov eax, pacmanx               ; new col
   ;     mov dl, al                     
   ;     add dl, col_start_point        ; adding the start point to get accurate Y
   ;     call gotoxy
   ;     mov al, 'P'
   ;     call writechar

   ;     ;decrement the lives 
   ;     dec lives
   ;     mov eax, lives
   ;     ; writing the updated lives
   ;     mov dh, 4   ; row
   ;     mov dl, 72   ; col
   ;     call gotoxy
   ;     call writedec

    done:
        ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    ret
inky_ghost_movement endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

placeBonusFood proc
    ; preserving the values
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov ecx, bonusFoodCount     ; number of bonuses to place
place_loop:
    ; pick random row
    mov eax, rows-3
    call RandomRange        ; 0 - rows-2
    inc eax                 ; 1 - rows-1
    mov ebx, eax           

    ; pick random col
    mov eax, cols-3
    call RandomRange        ; 0 - col-2
    inc eax                 ; 1 - col-1
    mov edx, eax          

    ; calc offset = row*(cols+1) + col
    mov eax, ebx          ; row
    imul eax, cols+1
    add eax, edx          ; col

    ; store '+' in maze
    mov edi, offset maze
    add edi, eax          ; index

    ; first check if the place is empty
    mov al, byte ptr [edi]
    cmp al, '.'       
    jne place_loop        ; if the space is occupied try again

    ; add the bonus food if space is available
    mov byte ptr [edi], '+'  

    ; draw it on screen
    mov dh, bl              ; dh = row
    add dh, row_start_point
    ; dl already as the col stored
    add dl, col_start_point
    call gotoxy
    mov al, '+'
    call WriteChar

    loop place_loop
     ; restore registers
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
    
    ; resetting
    mov  eax, white+(black*16)
    call SetTextColor
    ret
placeBonusFood endp


end main
