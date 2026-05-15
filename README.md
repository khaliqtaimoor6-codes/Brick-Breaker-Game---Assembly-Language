Brick Breaker Game – 8086 Assembly (MASM)

A classic Brick Breaker arcade game developed in x86 Assembly Language using MASM for the 8086 architecture. The project demonstrates low-level game development concepts including keyboard handling, collision detection, screen rendering, score management, and real-time game logic in a DOS environment.

Features
Paddle movement using keyboard controls
Ball physics and collision detection
Brick breaking mechanics
Score tracking system
Real-time gameplay loop
DOS-based graphics/text rendering
Written completely in Assembly Language (8086)
Technologies Used
8086 Assembly Language
MASM Assembler
DOSBox
x86 Architecture
How to Run
1. Install DOSBox

Download and install DOSBox Official Website

2. Place Project Files

Put all project files inside a folder, for example:

C:\masm

Make sure the folder contains:

brickbreaker.asm
MASM.EXE
LINK.EXE
3. Open DOSBox and Mount Folder
mount c c:\masm
c:
4. Assemble the Source File
masm brickbreaker.asm;
5. Link the Object File
link brickbreaker.obj;
6. Run the Game
brickbreaker
Controls
Left Arrow → Move paddle left
Right Arrow → Move paddle right
ESC → Exit game

Learning Objectives:

This project was built to explore:

1)Low-level programming concepts

2)Memory and register manipulation

3)Interrupt handling

4)Game loop implementation

5)Assembly-level graphics and input handling
