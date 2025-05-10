#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static uint8_t screen[40 * 25];

static int screen_to_petscii(int s)
{
    if (s <= 0x1f)
        return s+64;
    if (s <= 0x3f)
        return s;
    if (s == 0x5e)
        return s;
    if (s <= 0x5f)
        return s+128;
    if (s <= 0x7f)
        return s+64;
    if (s <= 0x9f)
        return s-128;
    if (s <= 0xfe)
        return s-64;
    return s;
}

int main(int argc, const char* argv[])
{
    bool reverse = false;

    while (true)
    {
        int b = getchar();
        if (b == EOF)
            break;

        if (b & 0x80)
        {
            if (!reverse)
                putchar(0x12);
            reverse = true;
        }
        else
        {
            if (reverse)
                putchar(0x92);
            reverse = false;
        }

        b = b & 0x7f;
        int p = screen_to_petscii(b);
        putchar(p);
    }
    return 0;
}