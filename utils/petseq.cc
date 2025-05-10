#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static uint8_t screen[40 * 25];

static int petscii_to_screen(int p)
{
    if (p <= 0x1f)
        return p + 128;
    if (p <= 0x3f)
        return p;
    if (p <= 0x5f)
        return p - 64;
    if (p <= 0x7f)
        return p - 32;
    if (p <= 0x9f)
        return p + 64;
    if (p <= 0xbf)
        return p - 64;
    if (p <= 0xfe)
        return p - 128;
    return p;
}

int main(int argc, const char* argv[])
{
    static bool reverse = false;
    static uint8_t* sptr = screen;

    while (true)
    {
        int b = getchar();
        if (b == EOF)
            break;

        if (((b >= 0x20) && (b <= 0x7f)) || ((b >= 0xa0) && (b <= 0xff)))
        {
            int p = petscii_to_screen(b);
            if (reverse)
                p |= 0x80;
            *sptr++ = p;
        }
        else
        {
            switch (b)
            {
                case 0x12:
                    reverse = true;
                    break;
                case 0x92:
                    reverse = false;
                    break;
            }
        }
    }

    fwrite(screen, 1, 1000, stdout);
    return 0;
}
