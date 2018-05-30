ml /c /Cx src\cpu\*.asm
ml /c /Cx src\text\*.asm
qcl /c src\text\putstrv.c
ml /c /Cx src\graph\*.asm
ml /c /Cx src\gdc\*.asm
ml /c /Cx src\grcg\*.asm
ml /c /Cx src\egc\*.asm
ml /c /Cx src\kbd\*.asm
ml /c /Cx src\rs232c\*.asm
ml /c /Cx src\peri\*.asm
lib @mklib.res ;
