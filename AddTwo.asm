; Dynamic Pac-Man Maze (MASM, Irvine32.inc)
INCLUDE Irvine32.inc

ROWS = 20
COLS = 40

.DATA
maze BYTE ROWS * (COLS + 1) DUP(' ')
newline BYTE 0
playerX DWORD 1
playerY DWORD 1

.CODE
main PROC
    call Clrscr
    call BuildMaze
    call PlacePlayer
    call PlaceBlocks
    call DrawMaze
GameLoop:
    call ReadKey
    cmp al, 0
    jne GameLoop
    call HandleInput
    call Clrscr
    call DrawMaze
    jmp GameLoop
main ENDP

; Build outer walls
BuildMaze PROC
    mov ecx, ROWS
    xor esi, esi
nextRow:
    mov edi, offset maze
    mov eax, esi
    imul eax, COLS + 1
    add edi, eax

    mov ebx, COLS
    mov al, ' '
fillRow:
    mov BYTE PTR [edi], al
    inc edi
    dec ebx
    jnz fillRow

    mov BYTE PTR [edi], 0

    mov edi, offset maze
    mov eax, esi
    imul eax, COLS + 1
    add edi, eax

    cmp esi, 0
    je topOrBottom
    cmp esi, ROWS - 1
    je topOrBottom
    mov BYTE PTR [edi], '#'
    mov BYTE PTR [edi + COLS - 1], '#'
    jmp skipRow
topOrBottom:
    mov ebx, 0
makeWall:
    mov BYTE PTR [edi + ebx], '#'
    inc ebx
    cmp ebx, COLS
    jl makeWall
skipRow:
    inc esi
    loop nextRow
    ret
BuildMaze ENDP

PlacePlayer PROC
    mov eax, 1
    mov playerY, eax
    mov playerX, eax
    mov al, 'P'
    call SetMazeChar
    ret
PlacePlayer ENDP

SetMazeChar PROC
    ; input: playerX, playerY, char in AL
    push edi
    mov edi, offset maze
    mov eax, playerY
    imul eax, COLS + 1
    add eax, playerX
    add edi, eax
    mov BYTE PTR [edi], al
    pop edi
    ret
SetMazeChar ENDP

PlaceBlocks PROC
    mov ecx, 10
nextBlock:
    call RandomRangeY
    mov playerY, eax
    call RandomRangeX
    mov playerX, eax
    mov al, '*'
    call SetMazeChar
    loop nextBlock
    ret
PlaceBlocks ENDP

RandomRangeX PROC
    ; returns 1 to COLS - 2
    mov eax, COLS - 2
    call RandomRange
    inc eax
    ret
RandomRangeX ENDP

RandomRangeY PROC
    ; returns 1 to ROWS - 2
    mov eax, ROWS - 2
    call RandomRange
    inc eax
    ret
RandomRangeY ENDP

DrawMaze PROC
    push ecx
    push edx
    mov ecx, 0
nextRow:
    mov edx, offset maze
    mov eax, ecx
    imul eax, COLS + 1
    add edx, eax
    mov dh, cl
    mov dl, 0
    call Gotoxy
    call WriteString
    inc ecx
    cmp ecx, ROWS
    jl nextRow
    pop edx
    pop ecx
    ret
DrawMaze ENDP

; Movement and collision logic to be added
HandleInput PROC
    ; placeholder for movement logic
    ret
HandleInput ENDP

END main
