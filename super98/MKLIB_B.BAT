tasm /mx /jmasm51 /jquirks src\cpu\*.asm
tasm /mx /jmasm51 /jquirks src\text\*.asm
bcc -c src\text\putstrv.c
tasm /mx /jmasm51 /jquirks src\graph\*.asm
tasm /mx /jmasm51 /jquirks src\gdc\*.asm
tasm /mx /jmasm51 /jquirks src\grcg\*.asm
tasm /mx /jmasm51 /jquirks src\egc\*.asm
tasm /mx /jmasm51 /jquirks src\kbd\*.asm
tasm /mx /jmasm51 /jquirks src\rs232c\*.asm
tasm /mx /jmasm51 /jquirks src\peri\*.asm
tlib @mklib.res
