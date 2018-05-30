#include <stdio.h>

int main(void)
{
    int ch,n;

    fputs("SAMPLE TERMINAL PROGRAM. ESC:EXIT\n",stderr);

    RsOpen(8,1,2,0,2);
    for (;;) {
        ch = 0xff & bdos(6,0xff,0);
        if (ch == 0x1b) {
            break;
        }
        if (ch != 0) {
            TransData(ch);
        }
        for (n = 0; n < 40; n++) {
            if (ReceiveLength() == 0) {
                break;
            }
            ch = ReceiveData();
            bdos(6,(ch == 0xff)? ' ': ch,0);
        }
    }
    RsClose();

    fputs("\nEXIT\n",stderr);
    return (0);
}
