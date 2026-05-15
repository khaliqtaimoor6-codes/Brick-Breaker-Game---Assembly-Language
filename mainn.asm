.MODEL SMALL
.STACK 100h

.DATA
; ------------------------------------------------------------
; Brick Breaker - Iteration 3 Complete Game System
;
; Scope:
; - Mode 13h graphics on every screen
; - Rectangle drawing through direct A000h video memory writes
; - Iteration 3: Three levels, progression, bonuses, score, lives and win/game-over flow
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
gameHelp        DB 'A/D OR ARROWS MOVE  ESC MENU',0
gameOverTitle   DB 'GAME OVER',0
levelClearTitle DB 'LEVEL CLEAR',0
winTitle        DB 'YOU WIN!',0
finalText       DB 'FINAL SCORE',0
returnText      DB 'PRESS ENTER FOR MENU',0
nextLevelText   DB 'PRESS ENTER FOR NEXT LEVEL',0
bonusSlowText   DB 'SLOW BALL',0
bonusFastText   DB 'FAST BALL',0
bonusLifeText   DB 'EXTRA LIFE',0
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

paddleX         DW 130
paddleY         DW 182
paddleW         DW 60
paddleH         DW 6
paddleStep      DW 10
ballX           DW 158
ballY           DW 150
ballSize        DW 4
ballDX          DW 2
ballDY          DW -2
prevPaddleX     DW 130
prevBallX       DW 158
prevBallY       DW 150
score           DW 0
lives           DB 3
bricksLeft      DB 32
gameDone        DB 0
endReason       DB 0
currentLevel    DB 1
brickIndex      DB 0
brickHitX       DW 0
brickHitY       DW 0
brickStates     DB 32 DUP(1)
bonusActive     DB 0
bonusType       DB 0
bonusX          DW 0
bonusY          DW 0
prevBonusX      DW 0
prevBonusY      DW 0
randSeed        DB 5

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
    call GameLayoutScreen
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
    call InitGame

GameLoop:
    call SavePreviousPositions
    call ReadGameInput
    cmp gameDone, 1
    je GameLoopDone
    call UpdateBall
    call UpdateBonus
    call DrawGameFrame
    call FrameDelay
    cmp gameDone, 0
    je GameLoop

GameLoopDone:
    cmp endReason, 2
    jne ShowGameEnd
    cmp currentLevel, 3
    jae FinalWin
    call LevelTransitionScreen
    inc currentLevel
    call InitLevel
    jmp GameLoop

FinalWin:
    mov endReason, 1

ShowGameEnd:
    call GameOverScreen
    ret
GameLayoutScreen ENDP

InitGame PROC
    mov score, 0
    mov lives, 3
    mov currentLevel, 1
    call UpdateScoreText
    call UpdateLivesText
    call InitLevel
    ret
InitGame ENDP

InitLevel PROC
    push ax
    push bx
    push cx
    push di

    mov paddleX, 130
    mov prevPaddleX, 130
    mov paddleW, 60
    mov ballX, 158
    mov ballY, 150
    mov prevBallX, 158
    mov prevBallY, 150
    mov bonusActive, 0
    mov gameDone, 0
    mov endReason, 0

    mov cx, 32
    mov di, OFFSET brickStates
    mov al, 1
InitBrickLoop:
    mov [di], al
    inc di
    loop InitBrickLoop

    call ApplyLevelLayout
    call SetLevelSpeed
    call UpdateLevelText
    call DrawStaticGameFrame

    pop di
    pop cx
    pop bx
    pop ax
    ret
InitLevel ENDP

ApplyLevelLayout PROC
    mov bricksLeft, 32
    cmp currentLevel, 1
    je LevelLayoutDone
    cmp currentLevel, 2
    je LevelTwoLayout
    jmp LevelThreeLayout

LevelTwoLayout:
    mov brickStates[0], 0
    mov brickStates[7], 0
    mov brickStates[8], 0
    mov brickStates[15], 0
    mov brickStates[16], 0
    mov brickStates[23], 0
    mov brickStates[24], 0
    mov brickStates[31], 0
    mov bricksLeft, 24
    jmp LevelLayoutDone

LevelThreeLayout:
    mov brickStates[1], 0
    mov brickStates[3], 0
    mov brickStates[5], 0
    mov brickStates[7], 0
    mov brickStates[8], 0
    mov brickStates[10], 0
    mov brickStates[12], 0
    mov brickStates[14], 0
    mov brickStates[17], 0
    mov brickStates[19], 0
    mov brickStates[21], 0
    mov brickStates[23], 0
    mov bricksLeft, 20

LevelLayoutDone:
    ret
ApplyLevelLayout ENDP

SetLevelSpeed PROC
    cmp currentLevel, 1
    je LevelOneSpeed
    cmp currentLevel, 2
    je LevelTwoSpeed

    mov ballDX, 3
    mov ballDY, -3
    ret

LevelOneSpeed:
    mov ballDX, 2
    mov ballDY, -2
    ret

LevelTwoSpeed:
    mov ballDX, 2
    mov ballDY, -3
    ret
SetLevelSpeed ENDP

UpdateLevelText PROC
    push ax

    mov al, currentLevel
    add al, '0'
    mov hudLevel+6, al

    pop ax
    ret
UpdateLevelText ENDP

SavePreviousPositions PROC
    push ax

    mov ax, paddleX
    mov prevPaddleX, ax
    mov ax, ballX
    mov prevBallX, ax
    mov ax, ballY
    mov prevBallY, ax
    mov ax, bonusX
    mov prevBonusX, ax
    mov ax, bonusY
    mov prevBonusY, ax

    pop ax
    ret
SavePreviousPositions ENDP

ReadGameInput PROC
    push ax

    mov ah, 01h
    int 16h
    jz ReadInputDone

    mov ah, 00h
    int 16h
    cmp al, 27
    je InputQuit
    cmp al, 'a'
    je MoveLeft
    cmp al, 'A'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp al, 'D'
    je MoveRight
    cmp al, 0
    jne ReadInputDone
    cmp ah, 4Bh
    je MoveLeft
    cmp ah, 4Dh
    je MoveRight
    jmp ReadInputDone

MoveLeft:
    mov ax, paddleX
    cmp ax, 14
    jbe ClampLeft
    sub ax, paddleStep
    cmp ax, 14
    jae StoreLeft
ClampLeft:
    mov ax, 14
StoreLeft:
    mov paddleX, ax
    jmp ReadInputDone

MoveRight:
    mov ax, paddleX
    add ax, paddleStep
    cmp ax, 246
    jbe StoreRight
    mov ax, 246
StoreRight:
    mov paddleX, ax
    jmp ReadInputDone

InputQuit:
    mov gameDone, 1
    mov endReason, 0

ReadInputDone:
    pop ax
    ret
ReadGameInput ENDP

UpdateBall PROC
    push ax

    inc randSeed
    mov ax, ballDX
    add ballX, ax
    mov ax, ballDY
    add ballY, ax

    call CheckWallCollision
    call CheckPaddleCollision
    call CheckBrickCollision
    call CheckBallMiss

    pop ax
    ret
UpdateBall ENDP

UpdateBonus PROC
    push ax
    cmp bonusActive, 1
    je BonusFalls
    jmp BonusUpdateDone

BonusFalls:
    add bonusY, 2
    call CheckBonusPaddle
    cmp bonusActive, 1
    jne BonusUpdateDone
    mov ax, bonusY
    cmp ax, 194
    jle BonusUpdateDone
    mov bonusActive, 0

BonusUpdateDone:
    pop ax
    ret
UpdateBonus ENDP

CheckBonusPaddle PROC
    push ax
    push bx

    mov ax, bonusY
    add ax, 6
    cmp ax, paddleY
    jge BonusCheckY2
    jmp BonusNoCatch

BonusCheckY2:
    mov ax, bonusY
    mov bx, paddleY
    add bx, paddleH
    cmp ax, bx
    jle BonusCheckX1
    jmp BonusNoCatch

BonusCheckX1:
    mov ax, bonusX
    add ax, 8
    cmp ax, paddleX
    jge BonusCheckX2
    jmp BonusNoCatch

BonusCheckX2:
    mov ax, paddleX
    add ax, paddleW
    cmp bonusX, ax
    jg BonusNoCatch

    mov bonusActive, 0
    call ApplyBonus

BonusNoCatch:
    pop bx
    pop ax
    ret
CheckBonusPaddle ENDP

ApplyBonus PROC
    cmp bonusType, 1
    je BonusSlow
    cmp bonusType, 2
    je BonusFast
    cmp bonusType, 3
    je BonusLife
    ret

BonusSlow:
    call SetBallSpeedSlow
    ret

BonusFast:
    call SetBallSpeedFast
    ret

BonusLife:
    cmp lives, 9
    jae BonusApplyDone
    inc lives
    call UpdateLivesText
    call DrawHud
BonusApplyDone:
    ret
ApplyBonus ENDP

SetBallSpeedSlow PROC
    call SetBallDxMagnitude2
    call SetBallDyMagnitude2
    ret
SetBallSpeedSlow ENDP

SetBallSpeedFast PROC
    call SetBallDxMagnitude3
    call SetBallDyMagnitude3
    ret
SetBallSpeedFast ENDP

SetBallDxMagnitude2 PROC
    cmp ballDX, 0
    jl BallDxSlowNegative
    cmp ballDX, 0
    je BallDxSlowPositive
    mov ballDX, 2
    ret
BallDxSlowNegative:
    mov ballDX, -2
    ret
BallDxSlowPositive:
    mov ballDX, 2
    ret
SetBallDxMagnitude2 ENDP

SetBallDyMagnitude2 PROC
    cmp ballDY, 0
    jl BallDySlowNegative
    mov ballDY, 2
    ret
BallDySlowNegative:
    mov ballDY, -2
    ret
SetBallDyMagnitude2 ENDP

SetBallDxMagnitude3 PROC
    cmp ballDX, 0
    jl BallDxFastNegative
    cmp ballDX, 0
    je BallDxFastPositive
    mov ballDX, 3
    ret
BallDxFastNegative:
    mov ballDX, -3
    ret
BallDxFastPositive:
    mov ballDX, 3
    ret
SetBallDxMagnitude3 ENDP

SetBallDyMagnitude3 PROC
    cmp ballDY, 0
    jl BallDyFastNegative
    mov ballDY, 3
    ret
BallDyFastNegative:
    mov ballDY, -3
    ret
SetBallDyMagnitude3 ENDP

CheckWallCollision PROC
    push ax

    mov ax, ballX
    cmp ax, 12
    jge CheckRightWall
    mov ballX, 12
    neg ballDX

CheckRightWall:
    mov ax, ballX
    cmp ax, 304
    jle CheckTopWall
    mov ballX, 304
    neg ballDX

CheckTopWall:
    mov ax, ballY
    cmp ax, 24
    jge WallDone
    mov ballY, 24
    neg ballDY

WallDone:
    pop ax
    ret
CheckWallCollision ENDP

CheckPaddleCollision PROC
    push ax
    push bx

    mov ax, ballDY
    cmp ax, 0
    jge PaddleCheckY1
    jmp PaddleDone

PaddleCheckY1:
    mov ax, ballY
    add ax, ballSize
    cmp ax, paddleY
    jge PaddleCheckY2
    jmp PaddleDone

PaddleCheckY2:
    mov ax, ballY
    mov bx, paddleY
    add bx, paddleH
    cmp ax, bx
    jle PaddleCheckX1
    jmp PaddleDone

PaddleCheckX1:
    mov ax, ballX
    add ax, ballSize
    cmp ax, paddleX
    jl PaddleDone
    mov ax, paddleX
    add ax, paddleW
    cmp ballX, ax
    jg PaddleDone

    mov ax, paddleY
    sub ax, ballSize
    mov ballY, ax

    ; Bounce angle depends on where the ball center hits the paddle.
    mov ax, ballX
    add ax, 2
    sub ax, paddleX
    cmp ax, 12
    jb PaddleFarLeft
    cmp ax, 24
    jb PaddleMidLeft
    cmp ax, 36
    jb PaddleCenter
    cmp ax, 48
    jb PaddleMidRight
    call BounceFarRight
    jmp PaddleDone
PaddleFarLeft:
    call BounceFarLeft
    jmp PaddleDone
PaddleMidLeft:
    call BounceMidLeft
    jmp PaddleDone
PaddleCenter:
    call BounceCenter
    jmp PaddleDone
PaddleMidRight:
    call BounceMidRight

PaddleDone:
    pop bx
    pop ax
    ret
CheckPaddleCollision ENDP

BounceFarLeft PROC
    cmp currentLevel, 1
    je BFL1
    cmp currentLevel, 2
    je BFL2
    mov ballDX, -3
    mov ballDY, -3
    ret
BFL1:
    mov ballDX, -2
    mov ballDY, -2
    ret
BFL2:
    mov ballDX, -3
    mov ballDY, -2
    ret
BounceFarLeft ENDP

BounceMidLeft PROC
    cmp currentLevel, 1
    je BML1
    cmp currentLevel, 2
    je BML2
    mov ballDX, -2
    mov ballDY, -3
    ret
BML1:
    mov ballDX, -2
    mov ballDY, -2
    ret
BML2:
    mov ballDX, -2
    mov ballDY, -3
    ret
BounceMidLeft ENDP

BounceCenter PROC
    cmp currentLevel, 1
    je BC1
    mov ballDX, 0
    mov ballDY, -3
    ret
BC1:
    mov ballDX, 0
    mov ballDY, -2
    ret
BounceCenter ENDP

BounceMidRight PROC
    cmp currentLevel, 1
    je BMR1
    cmp currentLevel, 2
    je BMR2
    mov ballDX, 2
    mov ballDY, -3
    ret
BMR1:
    mov ballDX, 2
    mov ballDY, -2
    ret
BMR2:
    mov ballDX, 2
    mov ballDY, -3
    ret
BounceMidRight ENDP

BounceFarRight PROC
    cmp currentLevel, 1
    je BFR1
    cmp currentLevel, 2
    je BFR2
    mov ballDX, 3
    mov ballDY, -3
    ret
BFR1:
    mov ballDX, 2
    mov ballDY, -2
    ret
BFR2:
    mov ballDX, 3
    mov ballDY, -2
    ret
BounceFarRight ENDP

CheckBrickCollision PROC
    push ax
    push bx
    push cx
    push dx

    mov brickIndex, 0

BrickCheckLoop:
    cmp brickIndex, 32
    jb BrickMaybeCheck
    jmp BrickCheckDone

BrickMaybeCheck:
    xor bx, bx
    mov bl, brickIndex
    cmp brickStates[bx], 1
    jne NextBrickCheck

    call GetBrickPosition

    mov ax, ballX
    add ax, ballSize
    cmp ax, brickHitX
    jl NextBrickCheck
    mov ax, brickHitX
    add ax, 30
    cmp ballX, ax
    jg NextBrickCheck

    mov ax, ballY
    add ax, ballSize
    cmp ax, brickHitY
    jl NextBrickCheck
    mov ax, brickHitY
    add ax, 10
    cmp ballY, ax
    jg NextBrickCheck

    xor bx, bx
    mov bl, brickIndex
    mov brickStates[bx], 0
    dec bricksLeft
    add score, 10
    call UpdateScoreText
    call DrawHud
    call EraseHitBrick
    call TrySpawnBonus
    call MoveBallOutsideBrick
    neg ballDY
    cmp bricksLeft, 0
    jne BrickCheckDone
    mov gameDone, 1
    mov endReason, 2
    jmp BrickCheckDone

NextBrickCheck:
    inc brickIndex
    jmp BrickCheckLoop

BrickCheckDone:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CheckBrickCollision ENDP

TrySpawnBonus PROC
    push ax
    push bx
    push dx

    cmp bonusActive, 1
    je SpawnBonusDone

    mov al, randSeed
    add al, brickIndex
    add al, currentLevel
    mov randSeed, al
    and al, 03h
    cmp al, 0
    jne SpawnBonusDone

    mov ax, brickHitX
    add ax, 11
    mov bonusX, ax
    mov prevBonusX, ax
    mov ax, brickHitY
    add ax, 10
    mov bonusY, ax
    mov prevBonusY, ax

    xor ax, ax
    mov al, randSeed
    xor dx, dx
    mov bx, 3
    div bx
    inc dl
    mov bonusType, dl
    mov bonusActive, 1

SpawnBonusDone:
    pop dx
    pop bx
    pop ax
    ret
TrySpawnBonus ENDP

MoveBallOutsideBrick PROC
    push ax

    mov ax, ballDY
    cmp ax, 0
    jl HitBrickFromBelow

    mov ax, brickHitY
    sub ax, ballSize
    mov ballY, ax
    jmp MoveOutsideDone

HitBrickFromBelow:
    mov ax, brickHitY
    add ax, 10
    mov ballY, ax

MoveOutsideDone:
    pop ax
    ret
MoveBallOutsideBrick ENDP

GetBrickPosition PROC
    push ax
    push bx
    push cx
    push dx

    xor ax, ax
    mov al, brickIndex
    mov bl, 8
    div bl                  ; AL = row, AH = column
    xor bx, bx
    mov bl, ah
    mov brickColIdx, bx

    xor bx, bx
    mov bl, al
    mov ax, bx
    mov cl, 4
    shl ax, cl
    add ax, 34
    mov brickHitY, ax

    xor bx, bx
    mov bx, brickColIdx
    mov ax, bx
    mov dx, bx
    mov cl, 5
    shl ax, cl
    mov cl, 2
    shl dx, cl
    add ax, dx
    add ax, 18
    mov brickHitX, ax

    pop dx
    pop cx
    pop bx
    pop ax
    ret
GetBrickPosition ENDP

CheckBallMiss PROC
    push ax

    mov ax, ballY
    cmp ax, 196
    jle MissDone

    cmp lives, 0
    je MissDone
    dec lives
    call UpdateLivesText
    call DrawHud
    cmp lives, 0
    je NoLivesLeft

    mov ballX, 158
    mov ballY, 150
    mov ballDX, 2
    mov ballDY, -2
    jmp MissDone

NoLivesLeft:
    mov gameDone, 1
    mov endReason, 0

MissDone:
    pop ax
    ret
CheckBallMiss ENDP

DrawStaticGameFrame PROC
    mov al, 0
    call ClearScreen

    call DrawHud

    ; Playfield frame
    mov bx, 18
    mov cx, 0
    mov si, 320
    mov di, 2
    mov al, 11
    call FillRect

    mov bx, 22
    mov cx, 10
    mov si, 300
    mov di, 2
    mov al, 11
    call FillRect

    mov bx, 22
    mov cx, 10
    mov si, 2
    mov di, 174
    mov al, 11
    call FillRect

    mov bx, 22
    mov cx, 308
    mov si, 2
    mov di, 174
    mov al, 11
    call FillRect

    call DrawBrickGrid
    call DrawPaddle
    call DrawBall
    ret
DrawStaticGameFrame ENDP

DrawHud PROC
    mov bx, 0
    mov cx, 0
    mov si, 320
    mov di, 18
    mov al, 0
    call FillRect

    mov dh, 0
    mov dl, 2
    mov bl, 11
    mov si, OFFSET hudScore
    call PrintAt

    mov dh, 0
    mov dl, 16
    mov bl, 11
    mov si, OFFSET hudLives
    call PrintAt

    mov dh, 1
    mov dl, 16
    mov bl, 14
    mov si, OFFSET hudLevel
    call PrintAt

    mov dh, 0
    mov dl, 28
    mov bl, 11
    mov si, OFFSET playerName
    call PrintAt
    ret
DrawHud ENDP

DrawGameFrame PROC
    call ErasePreviousPaddle
    call ErasePreviousBall
    call ErasePreviousBonus
    call DrawPaddle
    call DrawBall
    call DrawBonus
    ret
DrawGameFrame ENDP

ErasePreviousPaddle PROC
    mov bx, paddleY
    mov cx, prevPaddleX
    mov si, paddleW
    add si, 4
    mov di, paddleH
    add di, 4
    mov al, 0
    call FillRect
    ret
ErasePreviousPaddle ENDP

ErasePreviousBall PROC
    mov bx, prevBallY
    mov cx, prevBallX
    mov si, ballSize
    mov di, ballSize
    mov al, 0
    call FillRect
    ret
ErasePreviousBall ENDP

EraseHitBrick PROC
    mov bx, brickHitY
    mov cx, brickHitX
    mov si, 32
    mov di, 12
    mov al, 0
    call FillRect
    ret
EraseHitBrick ENDP

ErasePreviousBonus PROC
    mov bx, prevBonusY
    mov cx, prevBonusX
    mov si, 8
    mov di, 6
    mov al, 0
    call FillRect
    ret
ErasePreviousBonus ENDP

DrawPaddle PROC
    mov bx, paddleY
    add bx, 2
    mov cx, paddleX
    add cx, 2
    mov si, paddleW
    mov di, paddleH
    mov al, 8
    call FillRect

    mov bx, paddleY
    mov cx, paddleX
    mov si, paddleW
    mov di, paddleH
    mov al, 13
    call FillRect
    ret
DrawPaddle ENDP

DrawBall PROC
    mov bx, ballY
    mov cx, ballX
    mov si, ballSize
    mov di, ballSize
    mov al, 15
    call FillRect
    ret
DrawBall ENDP

DrawBonus PROC
    cmp bonusActive, 1
    je DrawBonusActive
    ret

DrawBonusActive:
    mov al, 10
    cmp bonusType, 1
    je BonusColorReady
    mov al, 12
    cmp bonusType, 2
    je BonusColorReady
    mov al, 14

BonusColorReady:
    mov bx, bonusY
    mov cx, bonusX
    mov si, 8
    mov di, 6
    call FillRect
    ret
DrawBonus ENDP

DrawBrickGrid PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov brickIndex, 0

DrawBrickLoop:
    cmp brickIndex, 32
    jae BrickDone
    xor bx, bx
    mov bl, brickIndex
    cmp brickStates[bx], 1
    jne SkipBrickDraw

    call GetBrickPosition

    xor ax, ax
    mov al, brickIndex
    mov bl, 8
    div bl                  ; AL = row

    mov dl, 12
    cmp al, 1
    jne BrickColor2
    mov dl, 13
BrickColor2:
    cmp al, 2
    jne BrickColor3
    mov dl, 11
BrickColor3:
    cmp al, 3
    jne BrickShadow
    mov dl, 10

BrickShadow:
    mov bx, brickHitY
    add bx, 2
    mov cx, brickHitX
    add cx, 2
    mov si, 30
    mov di, 10
    mov al, 8
    call FillRect

    mov bx, brickHitY
    mov cx, brickHitX
    mov si, 30
    mov di, 10
    mov al, dl
    call FillRect

SkipBrickDraw:
    inc brickIndex
    jmp DrawBrickLoop

BrickDone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawBrickGrid ENDP

UpdateScoreText PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    mov ax, score
    mov bx, 10
    mov cx, 5
    mov di, OFFSET scoreValue
    add di, 4

ScoreDigitLoop:
    xor dx, dx
    div bx
    add dl, '0'
    mov [di], dl
    dec di
    loop ScoreDigitLoop

    mov cx, 5
    mov si, OFFSET scoreValue
    mov di, OFFSET hudScore
    add di, 6
CopyScoreLoop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop CopyScoreLoop

    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
UpdateScoreText ENDP

UpdateLivesText PROC
    push ax
    mov al, lives
    add al, '0'
    mov hudLives+6, al
    pop ax
    ret
UpdateLivesText ENDP

FrameDelay PROC
    push ax
    push cx
    push dx

    mov ah, 86h
    mov cx, 0
    mov dx, 24000
    int 15h
    jnc DelayDone

    mov cx, 3600
DelayLoop:
    loop DelayLoop

DelayDone:
    pop dx
    pop cx
    pop ax
    ret
FrameDelay ENDP

GameOverScreen PROC
    mov al, 0
    call ClearScreen

    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 193
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
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    mov bx, 54
    mov cx, 48
    mov si, 224
    mov di, 82
    mov al, 13
    call FillRect
    mov bx, 56
    mov cx, 50
    mov si, 220
    mov di, 78
    mov al, 0
    call FillRect

    mov dh, 8
    mov dl, 15
    mov bl, 12
    mov si, OFFSET gameOverTitle
    cmp endReason, 1
    jne PrintEndTitle
    mov dl, 15
    mov bl, 10
    mov si, OFFSET winTitle
PrintEndTitle:
    call PrintAt

    mov dh, 12
    mov dl, 10
    mov bl, 14
    mov si, OFFSET finalText
    call PrintAt

    mov dh, 12
    mov dl, 24
    mov bl, 15
    mov si, OFFSET scoreValue
    call PrintAt

    mov dh, 18
    mov dl, 10
    mov bl, 10
    mov si, OFFSET returnText
    call PrintAt

WaitReturn:
    mov ah, 00h
    int 16h
    cmp al, 13
    jne WaitReturn
    ret
GameOverScreen ENDP

LevelTransitionScreen PROC
    mov al, 0
    call ClearScreen

    mov bx, 5
    mov cx, 5
    mov si, 310
    mov di, 2
    mov al, 11
    call FillRect
    mov bx, 193
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
    mov bx, 5
    mov cx, 313
    mov si, 2
    mov di, 190
    mov al, 11
    call FillRect

    mov dh, 8
    mov dl, 14
    mov bl, 10
    mov si, OFFSET levelClearTitle
    call PrintAt

    mov dh, 12
    mov dl, 10
    mov bl, 14
    mov si, OFFSET finalText
    call PrintAt

    mov dh, 12
    mov dl, 24
    mov bl, 15
    mov si, OFFSET scoreValue
    call PrintAt

    mov dh, 18
    mov dl, 7
    mov bl, 10
    mov si, OFFSET nextLevelText
    call PrintAt

WaitNextLevel:
    mov ah, 00h
    int 16h
    cmp al, 13
    jne WaitNextLevel
    ret
LevelTransitionScreen ENDP

END main
