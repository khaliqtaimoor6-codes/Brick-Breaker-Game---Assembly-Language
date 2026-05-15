.MODEL SMALL
.STACK 100h

.DATA
; ------------------------------------------------------------
; Brick Breaker - Iteration 1 Graphics/UI Prototype
;
; Scope:
; - Mode 13h graphics on every screen
; - Rectangle drawing through direct A000h video memory writes
; - Iteration 1: Static screens only: no ball movement, no collision, no score logic
; ------------------------------------------------------------

titleText       DB 'BRICK BREAKER',0
homeSubText     DB 'PRESS ANY KEY TO START',0
nameTitle       DB 'ENTER PLAYER NAME',0
nameHint        DB 'ENTER=CONTINUE  BACKSPACE=ERASE',0
menuTitle       DB 'MAIN MENU',0
startText       DB 'START GAME',0
instText        DB 'INSTRUCTIONS',0
scoresText      DB 'HIGH SCORES',0
exitText        DB 'EXIT',0
instTitle       DB 'INSTRUCTIONS',0
instLine1       DB 'USE LEFT/RIGHT KEYS TO MOVE PADDLE',0
instLine2       DB 'BREAK ALL BRICKS TO CLEAR THE LEVEL',0
instLine3       DB 'DO NOT LET THE BALL FALL BELOW',0
backText        DB 'PRESS ANY KEY TO RETURN TO MENU',0
scoreTitle      DB 'HIGH SCORES',0
scoreValue      DB '00000',0
hudScore        DB 'SCORE 00000',0
hudLives        DB 'LIVES 3',0
hudLevel        DB 'LEVEL 1',0
gameHelp        DB 'PRESS ANY KEY TO RETURN',0
teamNames       DB 'ALI - TAIMOOR - WADOOD - JEHANGIR',0

playerName      DB 13 DUP(0)
nameLen         DB 0
menuChoice      DB 0

rectW           DW 0
rectH           DW 0
rectColor       DB 0
rectCol         DW 0
brickRowPx      DW 0
brickColIdx     DW 0
; --- Gameplay state (Iteration 2) ---
ballX           DW 160          ; Ball center X
ballY           DW 156          ; Ball center Y
ballPrevX       DW 160
ballPrevY       DW 156
ballDX          DW 2            ; Ball X direction 
ballDY          DW 2            ; Ball Y direction 

paddleX         DW 126          ; Paddle left edge X
paddleSpeed     DW 6            ; Pixels per frame
paddleWidth     DW 68           ; must match your drawn paddle width
paddleLeftEdge  DW 12           ; left boundary (matches playfield border X+2)
paddleRightEdge DW 298          ; right boundary (playfield right border X)

lives           DB 3
gameOver        DB 0
gameLastTick    DW 0            ; stores last timer tick for frame pacing
ballSize        DW 8            ; ball width and height in pixels
ballColor       DB 15           ; white

; --- Brick state array: 4 rows x 8 cols = 32 bytes ---
; 1 = alive, 0 = destroyed
brickState      DB 32 DUP(1)

; --- Brick dimensions (must match DrawBrickGrid) ---
brickW          DW 30
brickH          DW 10
brickTopY       DW 34           ; first row pixel Y
brickLeftX      DW 18           ; first col pixel X
brickColW       DW 36           ; col spacing (pixel col = 18 + col*36)
brickRowH       DW 16           ; row spacing (pixel row = 34 + row*16)

; --- Score ---
gameScore       DW 0

.CODE
main PROC
    mov ax, @data
    mov ds, ax

    call SetMode13h
    call HomeScreen
    call NameInputScreen

MenuAgain:
    call MainMenuScreen
    cmp al, 0
    je ShowGame
    cmp al, 1
    je ShowInstructions
    cmp al, 2
    je ShowScores
    jmp QuitProgram


    ShowGame:
    call GameLayoutScreen     ; Draw static layout first (keep as-is)
    call GameLoop             ; NEW: enter the live game loop
    jmp MenuAgain


ShowInstructions:
    call InstructionsScreen
    jmp MenuAgain

ShowScores:
    call HighScoresScreen
    jmp MenuAgain

QuitProgram:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
main ENDP

; ------------------------------------------------------------
; Video helpers
; ------------------------------------------------------------
SetMode13h PROC
    mov ax, 0013h
    int 10h
    ret
SetMode13h ENDP

; FillRect
; Inputs:
;   BX = top row in pixels
;   CX = left column in pixels
;   SI = width in pixels
;   DI = height in pixels
;   AL = color
; Uses direct writes to A000:0000 in Mode 13h.
FillRect PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov rectColor, al
    mov rectW, si
    mov rectH, di
    mov rectCol, cx

    mov ax, 0A000h
    mov es, ax

    ; offset = row * 320 + col = row * 256 + row * 64 + col
    mov ax, bx
    mov dx, bx
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl dx, cl
    add ax, dx
    add ax, rectCol
    mov di, ax

    mov dx, rectH
RectRowLoop:
    push di
    mov cx, rectW
    mov al, rectColor
    rep stosb
    pop di
    add di, 320
    dec dx
    jnz RectRowLoop

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
FillRect ENDP

ClearScreen PROC
    mov bx, 0
    mov cx, 0
    mov si, 320
    mov di, 200
    call FillRect
    ret
ClearScreen ENDP

; PrintAt
; Inputs:
;   DH = text row, DL = text column, BL = color, SI = zero-terminated string
; Uses BIOS graphics-mode text, not DOS string output.
PrintAt PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov ah, 02h
    mov bh, 0
    int 10h

PrintLoop:
    lodsb
    cmp al, 0
    je PrintDone
    mov ah, 0Eh
    mov bh, 0
    int 10h
    jmp PrintLoop

PrintDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintAt ENDP

WaitKey PROC
    mov ah, 00h
    int 16h
    ret
WaitKey ENDP

; ------------------------------------------------------------
; Screens
; ------------------------------------------------------------
HomeScreen PROC
    mov al, 0              ; Black background
    call ClearScreen

    ; Decorative background pattern
    mov bx, 18
    mov cx, 18
    mov si, 80
    mov di, 4
    mov al, 1              ; Blue accent
    call FillRect
    mov bx, 30
    mov cx, 220
    mov si, 72
    mov di, 4
    mov al, 5              ; Magenta accent
    call FillRect
    mov bx, 48
    mov cx, 18
    mov si, 4
    mov di, 32
    mov al, 3              ; Cyan accent
    call FillRect
    mov bx, 104
    mov cx, 284
    mov si, 4
    mov di, 42
    mov al, 4              ; Red accent
    call FillRect
    mov bx, 132
    mov cx, 22
    mov si, 62
    mov di, 3
    mov al, 2              ; Green accent
    call FillRect
    mov bx, 152
    mov cx, 204
    mov si, 88
    mov di, 3
    mov al, 6              ; Brown/gold accent
    call FillRect
    mov bx, 24
    mov cx, 136
    mov si, 10
    mov di, 10
    mov al, 9              ; Light blue block
    call FillRect
    mov bx, 166
    mov cx, 74
    mov si, 12
    mov di, 12
    mov al, 12             ; Light red block
    call FillRect
    mov bx, 148
    mov cx, 250
    mov si, 10
    mov di, 10
    mov al, 10             ; Light green block
    call FillRect

    ; Futuristic frame (outer border) Light Cyan (11)
    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect          ; Top border
    mov bx, 5
    mov cx, 5
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect          ; Left border
    mov bx, 193
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect          ; Bottom border
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect          ; Right border

    ; Title Box Shadow (Dark Gray 8)
    mov bx, 62
    mov cx, 42
    mov si, 240
    mov di, 50
    mov al, 8
    call FillRect

    ; Title Box Frame (Light Magenta 13)
    mov bx, 60
    mov cx, 40
    mov si, 240
    mov di, 50
    mov al, 13
    call FillRect

    ; Title Box Inner (Black 0)
    mov bx, 62
    mov cx, 42
    mov si, 236
    mov di, 46
    mov al, 0
    call FillRect

    ; Print text
    mov dh, 9
    mov dl, 13
    mov bl, 14             ; Yellow for title
    mov si, OFFSET titleText
    call PrintAt

    mov dh, 16
    mov dl, 8
    mov bl, 10             ; Light Green for "PRESS ANY KEY"
    mov si, OFFSET homeSubText
    call PrintAt

    mov dh, 21
    mov dl, 3
    mov bl, 11             ; Light Cyan for team names
    mov si, OFFSET teamNames
    call PrintAt

    call WaitKey
    ret
HomeScreen ENDP

NameInputScreen PROC
    mov nameLen, 0
    mov al, 0              ; Black background
    call ClearScreen

    ; Cyberpunk frame (outer border) Light Cyan (11)
    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 5
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect
    mov bx, 193
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    ; Instruction Box Shadow (Dark Gray 8)
    mov bx, 37
    mov cx, 32
    mov si, 260
    mov di, 110
    mov al, 8
    call FillRect

    ; Instruction Box Outer (Light Magenta 13)
    mov bx, 35
    mov cx, 30
    mov si, 260
    mov di, 110
    mov al, 13
    call FillRect

    ; Instruction Box Inner (Black 0)
    mov bx, 37
    mov cx, 32
    mov si, 256
    mov di, 106
    mov al, 0
    call FillRect

    mov dh, 6
    mov dl, 11
    mov bl, 14             ; Yellow Title
    mov si, OFFSET nameTitle
    call PrintAt

    mov dh, 15
    mov dl, 4
    mov bl, 7              ; Gray Hint
    mov si, OFFSET nameHint
    call PrintAt

NameLoop:
    call DrawNameBox
    mov ah, 00h
    int 16h

    cmp al, 13
    je CheckNameDone
    cmp al, 8
    je NameBackspace
    cmp al, 32
    jb NameLoop
    cmp al, 126
    ja NameLoop

    mov bl, nameLen
    cmp bl, 12
    jae NameLoop
    xor bh, bh
    mov playerName[bx], al
    inc nameLen
    jmp NameLoop

NameBackspace:
    cmp nameLen, 0
    je NameLoop
    dec nameLen
    mov bl, nameLen
    xor bh, bh
    mov playerName[bx], 0
    jmp NameLoop

CheckNameDone:
    cmp nameLen, 0
    je NameLoop
    ret
NameInputScreen ENDP

DrawNameBox PROC
    push ax
    push bx
    push cx
    push dx
    push si

    ; Input Box Shadow
    mov bx, 90
    mov cx, 77
    mov si, 170
    mov di, 22
    mov al, 8
    call FillRect

    ; Input Box Frame (Light Cyan 11)
    mov bx, 88
    mov cx, 75
    mov si, 170
    mov di, 22
    mov al, 11
    call FillRect

    ; Input Box Inner (Black 0)
    mov bx, 90
    mov cx, 77
    mov si, 166
    mov di, 18
    mov al, 0
    call FillRect

    mov ah, 02h
    mov bh, 0
    mov dh, 12
    mov dl, 11
    int 10h

    mov cl, nameLen
    xor ch, ch
    mov si, OFFSET playerName
    cmp cx, 0
    je DrawNameDone

DrawNameChars:
    lodsb
    mov ah, 0Eh
    mov bh, 0
    mov bl, 10             ; Light Green text for futuristic prompt
    int 10h
    loop DrawNameChars

DrawNameDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawNameBox ENDP

MainMenuScreen PROC
    mov menuChoice, 0

MenuDraw:
    mov al, 0              ; Black background
    call ClearScreen

    ; Futuristic frame (outer border) Light Cyan (11)
    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 5
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect
    mov bx, 193
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    ; Title Box Shadow (Dark Gray 8)
    mov bx, 20
    mov cx, 100
    mov si, 120
    mov di, 24
    mov al, 8
    call FillRect

    ; Title Box Frame (Light Magenta 13)
    mov bx, 18
    mov cx, 98
    mov si, 120
    mov di, 24
    mov al, 13
    call FillRect

    ; Title Box Inner (Black 0)
    mov bx, 20
    mov cx, 100
    mov si, 116
    mov di, 20
    mov al, 0
    call FillRect

    mov dh, 3
    mov dl, 15
    mov bl, 14             ; Yellow Title
    mov si, OFFSET menuTitle
    call PrintAt

    call DrawMenuItems

MenuKey:
    mov ah, 00h
    int 16h
    cmp al, 13
    je MenuSelect
    cmp al, 27
    je MenuExit
    cmp al, 0
    jne MenuKey
    cmp ah, 48h
    je MenuUp
    cmp ah, 50h
    je MenuDown
    jmp MenuKey

MenuUp:
    cmp menuChoice, 0
    je MenuKey
    dec menuChoice
    jmp MenuDraw

MenuDown:
    cmp menuChoice, 3
    je MenuKey
    inc menuChoice
    jmp MenuDraw

MenuSelect:
    mov al, menuChoice
    ret

MenuExit:
    mov al, 3
    ret
MainMenuScreen ENDP

DrawMenuItems PROC
    call DrawMenuHighlight

    mov dh, 8
    mov dl, 14
    mov bl, 11             ; Unselected Cyan
    cmp menuChoice, 0
    jne DM1
    mov bl, 14             ; Selected Yellow
DM1:
    mov si, OFFSET startText
    call PrintAt

    mov dh, 11
    mov dl, 13
    mov bl, 11
    cmp menuChoice, 1
    jne DM2
    mov bl, 14
DM2:
    mov si, OFFSET instText
    call PrintAt

    mov dh, 14
    mov dl, 14
    mov bl, 11
    cmp menuChoice, 2
    jne DM3
    mov bl, 14
DM3:
    mov si, OFFSET scoresText
    call PrintAt

    mov dh, 17
    mov dl, 18
    mov bl, 11
    cmp menuChoice, 3
    jne DM4
    mov bl, 14
DM4:
    mov si, OFFSET exitText
    call PrintAt
    ret
DrawMenuItems ENDP

DrawMenuHighlight PROC
    mov bx, 60
    cmp menuChoice, 0
    je DMHReady
    mov bx, 84
    cmp menuChoice, 1
    je DMHReady
    mov bx, 108
    cmp menuChoice, 2
    je DMHReady
    mov bx, 132

DMHReady:
    ; Draw hollow neon box for highlighter
    push bx                ; Save Y
    mov cx, 88
    mov si, 144
    mov di, 2
    mov al, 13             ; Neon Magenta
    call FillRect          ; Top edge
    
    pop bx
    push bx
    add bx, 16
    mov cx, 88
    mov si, 144
    mov di, 2
    mov al, 13
    call FillRect          ; Bottom edge
    
    pop bx
    push bx
    mov cx, 88
    mov si, 2
    mov di, 18
    mov al, 13
    call FillRect          ; Left edge
    
    pop bx
    mov cx, 230
    mov si, 2
    mov di, 18
    mov al, 13
    call FillRect          ; Right edge
    ret
DrawMenuHighlight ENDP

InstructionsScreen PROC
    mov al, 0              ; Black background
    call ClearScreen

    ; Futuristic frame (outer border) Light Cyan (11)
    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 5
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect
    mov bx, 193
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    ; Title Box Frame (Light Magenta 13)
    mov bx, 12
    mov cx, 80
    mov si, 160
    mov di, 24
    mov al, 13
    call FillRect

    ; Inner Title Box
    mov bx, 14
    mov cx, 82
    mov si, 156
    mov di, 20
    mov al, 0
    call FillRect

    mov dh, 2
    mov dl, 13
    mov bl, 14             ; Yellow Title
    mov si, OFFSET instTitle
    call PrintAt

    mov dh, 7
    mov dl, 3
    mov bl, 11             ; Light Cyan Text
    mov si, OFFSET instLine1
    call PrintAt

    mov dh, 10
    mov dl, 3
    mov bl, 11
    mov si, OFFSET instLine2
    call PrintAt

    mov dh, 13
    mov dl, 3
    mov bl, 12             ; Light Red Text
    mov si, OFFSET instLine3
    call PrintAt

    mov dh, 21
    mov dl, 5
    mov bl, 10             ; Light Green
    mov si, OFFSET backText
    call PrintAt

    call WaitKey
    ret
InstructionsScreen ENDP

HighScoresScreen PROC
    mov al, 0              ; Black background
    call ClearScreen

    ; Cyberpunk frame (outer border) Light Cyan (11)
    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 5
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect
    mov bx, 193
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    ; High Score Box Shadow
    mov bx, 40
    mov cx, 48
    mov si, 228
    mov di, 90
    mov al, 8
    call FillRect

    ; High Score Box Outer (Light Magenta 13)
    mov bx, 38
    mov cx, 46
    mov si, 228
    mov di, 90
    mov al, 13
    call FillRect

    ; High Score Box Inner (Black 0)
    mov bx, 40
    mov cx, 48
    mov si, 224
    mov di, 86
    mov al, 0
    call FillRect

    mov dh, 7
    mov dl, 14
    mov bl, 14             ; Yellow Title
    mov si, OFFSET scoreTitle
    call PrintAt

    mov dh, 12
    mov dl, 9
    mov bl, 15             ; White Text
    mov si, OFFSET playerName
    call PrintAt

    mov dh, 12
    mov dl, 25
    mov bl, 15             ; White Text
    mov si, OFFSET scoreValue
    call PrintAt

    mov dh, 21
    mov dl, 5
    mov bl, 10             ; Light Green
    mov si, OFFSET backText
    call PrintAt

    call WaitKey
    ret
HighScoresScreen ENDP

GameLayoutScreen PROC
    mov al, 0              ; Black background
    call ClearScreen

    ; HUD bar background (Black 0)
    mov bx, 0
    mov cx, 0
    mov si, 320
    mov di, 18
    mov al, 0
    call FillRect

    ; Score
    mov dh, 0
    mov dl, 2
    mov bl, 11             ; Cyan text
    mov si, OFFSET hudScore
    call PrintAt

    ; Lives
    mov dh, 0
    mov dl, 16
    mov bl, 11
    mov si, OFFSET hudLives
    call PrintAt

    ; Level
    mov dh, 1
    mov dl, 16
    mov bl, 14             ; Yellow text
    mov si, OFFSET hudLevel
    call PrintAt

    ; Username
    mov dh, 0
    mov dl, 28
    mov bl, 11
    mov si, OFFSET playerName
    call PrintAt

    ; Separator Line under HUD
    mov bx, 18
    mov cx, 0
    mov si, 320
    mov di, 2
    mov al, 11             ; Light Cyan
    call FillRect

    ; Playfield border - Top
    mov bx, 22
    mov cx, 10
    mov si, 300
    mov di, 2
    mov al, 11
    call FillRect

    ; Playfield border - Left
    mov bx, 22
    mov cx, 10
    mov si, 2
    mov di, 160
    mov al, 11
    call FillRect

    ; Playfield border - Right
    mov bx, 22
    mov cx, 308
    mov si, 2
    mov di, 160
    mov al, 11
    call FillRect

    ; Static brick grid: 8 columns x 4 rows
    call DrawBrickGrid

    ; Static paddle Shadow
    mov bx, 178
    mov cx, 128
    mov si, 68
    mov di, 7
    mov al, 8
    call FillRect

    ; Static paddle Main
    mov bx, 176
    mov cx, 126
    mov si, 68
    mov di, 7
    mov al, 13             ; Light Magenta
    call FillRect

    ; Static ball
    mov bx, 156
    mov cx, 156
    mov si, 8
    mov di, 8
    mov al, 15
    call FillRect

    

    ;call WaitKey
    ret
GameLayoutScreen ENDP

DrawBrickGrid PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dx, 0                   ; row index
BrickRow:
    cmp dx, 4
    jb  BrickRowOk
    jmp BrickDone
BrickRowOk:

    mov ax, dx
    mov cl, 4
    shl ax, cl
    add ax, 34
    mov brickRowPx, ax          ; Y = 34 + row*16

    mov cx, 0                   ; col index
    BrickCol:
    cmp cx, 8
    jb  BrickColOk
    jmp NextBrickRow
BrickColOk:

    ; Check brickState[row*8 + col]
    push dx
    push cx
    mov ax, dx
    mov bl, 8
    mul bl                      ; AX = row * 8
    pop cx
    add ax, cx                  ; AX = row*8 + col
    mov si, ax
    push dx
    mov dl, brickState[si]
    cmp dl, 0
    pop dx
    je SkipBrick                ; brick is dead, skip drawing

    ; Compute pixel X
    mov brickColIdx, cx
    mov ax, cx
    mov bx, ax
    mov cl, 5
    shl ax, cl
    mov cl, 2
    shl bx, cl
    add ax, bx
    add ax, 18                  ; X = 18 + col*36
    mov cx, ax
    pop dx                      ; restore row index

   mov al, 12
    cmp dx, 1
    je  DBG_Row1
    jmp BC2
DBG_Row1:
    mov al, 13
BC2:
    cmp dx, 2
    je  DBG_Row2
    jmp BC3
DBG_Row2:
    mov al, 11
BC3:
    cmp dx, 3
    je  DBG_Row3
    jmp BSDraw
DBG_Row3:
    mov al, 10

BSDraw:
    push ax
    mov bx, brickRowPx
    add bx, 2
    push cx
    add cx, 2
    mov si, 30
    mov di, 10
    mov al, 8
    call FillRect
    pop cx
    pop ax

    mov bx, brickRowPx
    mov si, 30
    mov di, 10
    call FillRect

    mov cx, brickColIdx
    inc cx
    jmp BrickCol

SkipBrick:
    pop dx                      ; restore row (was pushed before state check)

    ; Erase dead brick area (paint black)
    mov ax, cx
    mov bx, ax
    mov cl, 5
    shl ax, cl
    mov cl, 2
    shl bx, cl
    add ax, bx
    add ax, 18
    mov cx, ax

    mov bx, brickRowPx
    mov si, 32
    mov di, 12
    mov al, 0
    call FillRect

    mov cx, brickColIdx
    inc cx
    jmp BrickCol

NextBrickRow:
    inc dx
    jmp BrickRow

BrickDone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawBrickGrid ENDP

; --- Core game loop ---
GameLoop PROC
    mov gameOver, 0
    mov gameScore, 0            ; reset score each new game

    ; Reset all 32 bricks to alive
    mov cx, 32
    mov bx, 0
ResetBricks:
    mov brickState[bx], 1
    inc bx
    loop ResetBricks

    call DrawHUD                ; show initial 00000
    mov ah ,00h
    int 1Ah
    mov gameLastTick,dx

GameLoopTop:
    call ReadInput
    call UpdatePaddle
    call UpdateBall
    call CheckCollisions
    call DrawFrame
    call DrawHUD
    call FrameDelay

    cmp gameOver, 0
    je GameLoopTop

    call GameOverScreen
    ret
GameLoop ENDP


; --- STUB: Read keyboard input ---
ReadInput PROC
    push bx
    push cx
    push dx

    mov al, 0               ; default: no key

    mov ah, 01h
    int 16h                 ; check if key is waiting (ZF=1 means no key)
    jz ReadInputDone        ; no key pressed, return AL=0

    mov ah, 00h
    int 16h                 ; read key: AH=scancode, AL=ASCII

    mov al, ah              ; return scancode in AL

ReadInputDone:
    pop dx
    pop cx
    pop bx
    ret
ReadInput ENDP

; --- STUB: Move paddle based on input ---
UpdatePaddle PROC
    push ax
    push bx
    push dx

    ; AL already contains scancode from ReadInput (caller passes it)
    ; Check LEFT: Left Arrow (4Bh) or A (1Eh)
    cmp al, 4Bh
    je PaddleMoveLeft
    cmp al, 1Eh
    je PaddleMoveLeft

    ; Check RIGHT: Right Arrow (4Dh) or D (20h)
    cmp al, 4Dh
    je PaddleMoveRight
    cmp al, 20h
    je PaddleMoveRight

    jmp UpdatePaddleDone

PaddleMoveLeft:
    mov ax, paddleX
    sub ax, paddleSpeed
    cmp ax, paddleLeftEdge      ; hit left wall?
    jge PaddleSetX
    mov ax, paddleLeftEdge      ; clamp to left boundary
    jmp PaddleSetX

PaddleMoveRight:
    mov ax, paddleX
    add ax, paddleSpeed
    mov bx, paddleRightEdge
    sub bx, paddleWidth         ; rightmost valid X = right edge - paddle width
    cmp ax, bx
    jle PaddleSetX
    mov ax, bx                  ; clamp to right boundary

PaddleSetX:
    mov paddleX, ax

UpdatePaddleDone:
    pop dx
    pop bx
    pop ax
    ret
UpdatePaddle ENDP

; --- STUB: Move ball one step ---
UpdateBall PROC
    push ax
    push bx

    ; --- Move ball ---
    mov ax, ballX
    add ax, ballDX
    mov ballX, ax

    mov ax, ballY
    add ax, ballDY
    mov ballY, ax

    ; --- Left wall boundary ---
    mov ax, ballX
    cmp ax, 12              ; playfield left edge
    jg CheckRightWall
    mov ballX, 12
    neg ballDX              ; reverse X direction

CheckRightWall:
    mov ax, ballX
    add ax, ballSize
    cmp ax, 308             ; playfield right edge
    jl CheckTopWall
    mov ax, 308
    sub ax, ballSize
    mov ballX, ax
    neg ballDX

CheckTopWall:
    mov ax, ballY
    cmp ax, 24              ; playfield top edge (below HUD)
    jg CheckBottomWall
    mov ballY, 24
    neg ballDY

CheckBottomWall:
    mov ax, ballY
    add ax, ballSize
    cmp ax, 182             ; playfield bottom edge (above paddle zone)
    jl BallMoveDone
    ; Ball fell below paddle .. lose a life
    mov gameOver, 1         ; temporary: end game (lives logic added later)

BallMoveDone:
    pop bx
    pop ax
    ret
UpdateBall ENDP

; --- STUB: Check all collisions ---
CheckCollisions PROC
    push ax
    push bx
    push cx

    ; --- Ball/Paddle collision ---
    mov ax, ballY
    add ax, ballSize
    cmp ax, 176             ; ball bottom at paddle top
    jl CollisionDone
    cmp ax, 184             ; too far past paddle
    jg CollisionDone

    ; Check horizontal overlap
    mov ax, ballX
    cmp ax, paddleX
    jl CollisionDone        ; ball left of paddle left edge
    mov bx, paddleX
    add bx, paddleWidth
    cmp ax, bx
    jg CollisionDone        ; ball right of paddle right edge

    ; Bounce vertically
    neg ballDY
    mov ax, 176
    sub ax, ballSize
    mov ballY, ax           ; push ball above paddle surface

    ; --- Angle logic based on hit zone ---
    ; Divide paddle into 3 zones:
    ;   Left third  .. send ball left  (ballDX = -1)
    ;   Middle third ..keep ballDX as-is
    ;   Right third .. send ball right (ballDX = +1)

    mov ax, paddleWidth
    mov cx, 3
    xor dx, dx
    div cx                  ; AX = paddleWidth / 3 (one zone width)

    mov bx, paddleX
    add bx, ax              ; BX = start of middle zone
    mov cx, bx
    add cx, ax              ; CX = start of right zone

    mov ax, ballX

    cmp ax, bx              ; ball in left zone?
    jge CheckRightZone
    mov ballDX, -1
    jmp CollisionDone

CheckRightZone:
    cmp ax, cx              ; ball in right zone?
    jl CollisionDone        ; middle zone .. keep current DX
    mov ballDX, 1

CollisionDone:
    ; --- Brick collision (always checked, independent of paddle) ---
    call CheckBrickCollision

    pop cx
    pop bx
    pop ax
    ret
CheckCollisions ENDP

; --- DrawHUD: display score as 5-digit decimal string in HUD ---
; Converts gameScore (DW) to ASCII digits and prints at row 0, col 8
DrawHUD PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; --- Convert gameScore to 5 ASCII digits (in hudScore+6..+10) ---
    ; hudScore DB 'SCORE 00000',0
    ; digits start at offset 6 inside hudScore string

    mov ax, gameScore

    ; digit 5 (ones)
    xor dx, dx
    mov bx, 10
    div bx                      ; AX=quotient, DX=ones
    add dl, '0'
    mov hudScore[10], dl

    ; digit 4 (tens)
    xor dx, dx
    div bx
    add dl, '0'
    mov hudScore[9], dl

    ; digit 3 (hundreds)
    xor dx, dx
    div bx
    add dl, '0'
    mov hudScore[8], dl

    ; digit 2 (thousands)
    xor dx, dx
    div bx
    add dl, '0'
    mov hudScore[7], dl

    ; digit 1 (ten-thousands)
    xor dx, dx
    div bx
    add dl, '0'
    mov hudScore[6], dl

    ; --- Erase old score area in HUD ---
    mov bx, 0
    mov cx, 16                  ; col pixel = 2 text cols * 8px
    mov si, 88                  ; wide enough for "SCORE 00000"
    mov di, 8
    mov al, 0
    call FillRect

    ; --- Print updated score string ---
    mov dh, 0
    mov dl, 2
    mov bl, 11                  ; Cyan
    mov si, OFFSET hudScore
    call PrintAt

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawHUD ENDP

; --- STUB: Redraw paddle and ball positions ---
DrawFrame PROC
    push ax
    push bx
    push cx
    push si
    push di

    ; Erase old paddle area (draw black rectangle across full paddle zone)
    mov bx, 174
    mov cx, paddleLeftEdge  ; erase from left edge to right edge
    mov si, 288             ; full paddle zone width
    mov di, 12
    mov al, 0               ; black
    call FillRect

    ; Draw new paddle shadow
    mov bx, 178
    mov cx, paddleX
    add cx, 2               ; shadow offset
    mov si, paddleWidth
    mov di, 7
    mov al, 8               ; dark gray
    call FillRect

    ; Draw new paddle main
    mov bx, 176
    mov cx, paddleX
    mov si, paddleWidth
    mov di, 7
    mov al, 13              ; light magenta
    call FillRect

    ; Erase only previous ball position
    mov bx, ballPrevY
    mov cx, ballPrevX
    mov si, ballSize
    mov di, ballSize
    mov al, 0
    call FillRect

    ; Save current position as previous
    mov ax, ballX
    mov ballPrevX, ax
    mov ax, ballY
    mov ballPrevY, ax

    ; Draw ball at current position
    mov bx, ballY
    mov cx, ballX
    mov si, ballSize
    mov di, ballSize
    mov al, ballColor
    call FillRect

    pop di
    pop si

    pop cx
    pop bx
    pop ax
    ret
DrawFrame ENDP

; --- STUB: Small delay between frames ---
FrameDelay PROC
    push ax
    push cx
    push dx

WaitTick:
    mov ah, 00h
    int 1Ah                 ; CX:DX = current tick count (low word in DX)
    mov ax, dx
    sub ax, gameLastTick    ; ticks elapsed since last frame
    cmp ax, 1               ; wait for at least 1 ticks (~55ms=18fps)
    jb WaitTick             ; not enough time passed, keep waiting

    mov ah, 00h
    int 1Ah
    mov gameLastTick, dx    ; update last tick to now

    pop dx
    pop cx
    pop ax
    ret
FrameDelay ENDP

; --- STUB: Show game over screen ---
GameOverScreen PROC
    call WaitKey
    ret
GameOverScreen ENDP

CheckBrickCollision PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; -------------------------------------------------------
    ; AABB test: ball rect [ballX .. ballX+ballSize-1]
    ;                       [ballY .. ballY+ballSize-1]
    ; Brick row zone: [brickTopY .. brickTopY + 4*brickRowH)
    ; Brick col zone: [brickLeftX .. brickLeftX + 8*brickColW)
    ; We test the ball CENTER against cell boundaries to pick
    ; one row/col, then do a proper overlap against that brick.
    ; -------------------------------------------------------

    ; --- Quick zone reject on ball center Y ---
    mov ax, ballY
    add ax, 4                   ; ball center Y (ballSize/2 = 4)

    cmp ax, brickTopY
    jb  NoBrickHit

    mov bx, brickTopY
    add bx, 64                  ; 4 rows * 16 px spacing
    cmp ax, bx
    jae NoBrickHit

    ; row = (centerY - brickTopY) / brickRowH
    sub ax, brickTopY
    xor dx, dx
    mov bx, brickRowH
    div bx                      ; AX = row 0-3
    mov di, ax                  ; DI = row

    ; --- Quick zone reject on ball center X ---
    mov ax, ballX
    add ax, 4                   ; ball center X

    cmp ax, brickLeftX
    jb  NoBrickHit

    mov bx, brickLeftX
    add bx, 288                 ; 8 cols * 36 px
    cmp ax, bx
    jae NoBrickHit

    ; col = (centerX - brickLeftX) / brickColW
    sub ax, brickLeftX
    xor dx, dx
    mov bx, brickColW
    div bx                      ; AX = col 0-7
    mov si, ax                  ; SI = col

    ; --- Index = row*8 + col ---
    mov ax, di
    mov bl, 8
    mul bl
    add ax, si
    mov bx, ax                  ; BX = array index

    ; --- Alive check ---
    cmp brickState[bx], 0
    je  NoBrickHit

    ; --- Precise AABB overlap check ---
    ; Brick pixel rect: X=[brickLeftX + col*36 .. +30), Y=[brickTopY + row*16 .. +10)
    ; brick left X
    mov ax, si                  ; col
    mov cx, ax
    mov cl, 5
    shl ax, cl                  ; col * 32
    mov cx, si
    mov cl, 2
    shl cx, cl                  ; col * 4
    add ax, cx                  ; col * 36
    add ax, brickLeftX          ; brick left pixel X
    mov cx, ax                  ; CX = brickPixelX

    ; brick right X = brickPixelX + brickW (30)
    mov dx, cx
    add dx, 30                  ; DX = brickPixelX + 30

    ; ball right X = ballX + ballSize
    mov ax, ballX
    add ax, ballSize

    ; overlap X: ballX < brickRight  AND  ballRight > brickLeft
    cmp ballX, dx
    jge NoBrickHit
    cmp ax, cx
    jle NoBrickHit

    ; brick top Y
    mov ax, di                  ; row
    mov cx, ax
    mov cl, 4
    shl ax, cl                  ; row * 16
    add ax, brickTopY           ; brick top pixel Y
    mov cx, ax                  ; CX = brickPixelY

    ; brick bottom Y = brickPixelY + brickH (10)
    mov dx, cx
    add dx, 10                  ; DX = brickPixelY + 10

    ; ball bottom Y = ballY + ballSize
    mov ax, ballY
    add ax, ballSize

    ; overlap Y: ballY < brickBottom  AND  ballBottom > brickTop
    cmp ballY, dx
    jge NoBrickHit
    cmp ax, cx
    jle NoBrickHit

    ; ---- Collision confirmed ----

    ; --- Mark brick destroyed ---
    mov ax, di
    mov bl, 8
    mul bl
    add ax, si
    mov bx, ax
    mov brickState[bx], 0

    ; --- Erase brick visually (paint black over brick area) ---
    ; BrickPixelY is in CX (brickTop, computed above for Y check)
    ; Re-derive brickPixelY from DI (row)
    mov ax, di
    mov cl, 4
    shl ax, cl
    add ax, brickTopY           ; AX = brick top Y pixel
    push ax                     ; save for FillRect BX

    ; Re-derive brickPixelX from SI (col)
    mov ax, si
    mov bx, ax
    mov cl, 5
    shl ax, cl                  ; col*32
    mov cl, 2
    shl bx, cl                  ; col*4
    add ax, bx
    add ax, brickLeftX          ; AX = brick left X pixel
    mov cx, ax                  ; CX = left X for FillRect

    pop bx                      ; BX = top Y for FillRect
    mov si, 32                  ; erase full cell width (30 brick + gap)
    mov di, 12                  ; erase full cell height (10 brick + gap)
    mov al, 0                   ; black
    call FillRect

    ; --- Restore SI=col, DI=row from brickState index ---
    ; (they may have been modified; just skip — we already used them)

    ; --- Increment score by 10 ---
    add gameScore, 10

    ; --- Reverse ball Y direction (bounce off brick) ---
    neg ballDY

    ; --- Update HUD score display ---
    call DrawHUD

NoBrickHit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CheckBrickCollision ENDP

END main
;latest 0 update