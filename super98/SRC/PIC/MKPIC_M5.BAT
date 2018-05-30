masm crtv.asm;
link crtv.obj;
exe2bin crtv.exe
ren crtv.bin crtv.com
del crtv.exe

masm key_stat.asm;
link key_stat.obj;
exe2bin key_stat.exe
ren key_stat.bin key_stat.com
del key_stat.exe

masm key_vect.asm;
link key_vect.obj;
exe2bin key_vect.exe
ren key_vect.bin key_vect.com
del key_vect.exe

masm pic_vect.asm;
link pic_vect.obj;
exe2bin pic_vect.exe
ren pic_vect.bin pic_vect.com
del pic_vect.exe

masm timer.asm;
link timer.obj;
exe2bin timer.exe
ren timer.bin timer.com
del timer.exe
