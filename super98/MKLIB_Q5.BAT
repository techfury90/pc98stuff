masm /Mx src\cpu\cpulib.asm;

masm /Mx src\text\curform.asm;
masm /Mx src\text\getcur.asm;
masm /Mx src\text\getvram.asm;
qcl /Ox /c src\text\putstrv.c
masm /Mx src\text\putvram.asm;
masm /Mx src\text\setucgbi.asm;
masm /Mx src\text\setucgio.asm;
masm /Mx src\text\tojis.asm;
masm /Mx src\text\tojisfst.asm;
masm /Mx src\text\tosjis.asm;
masm /Mx src\text\tosjisfs.asm;

masm /Mx src\graph\ginit.asm;
masm /Mx src\graph\palette.asm;

masm /Mx src\gdc\gdc.asm;
masm /Mx src\gdc\gput.asm;

masm /Mx src\grcg\grcg.asm;

masm /Mx src\egc\egc.asm;

masm /Mx src\rs232c\getspeed.asm;
masm /Mx src\rs232c\rslib.asm;

masm /Mx src\kbd\kblib.asm;
masm /Mx src\kbd\key_stat.asm;

masm /Mx src\peri\disklib.asm;
masm /Mx src\peri\perilib.asm;

lib @mklib.res ;
