#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <FreeImagePlus.h>

int main(int argc, const char* argv[])
{
    fipImage image;
    image.load(argv[1]);

    if (image.getWidth() != 80)
    {
        fprintf(stderr, "width must be 80 pixels\n");
        exit(1);
    }
    if (image.getHeight() & 1)
    {
        fprintf(stderr, "height must be a multiple of two\n");
        exit(1);
    }
    if (image.getColorsUsed() == 0)
    {
        fprintf(stderr, "image must be indexed\n");
        exit(1);
    }

    for (int y = image.getHeight()-2; y>=0; y -= 2)
    {
        for (int x = 0; x<image.getWidth(); x+=2)
        {
            uint8_t tl, tr, bl, br;

            image.getPixelIndex(x + 0, y + 1, &tl);
            image.getPixelIndex(x + 1, y + 1, &tr);
            image.getPixelIndex(x + 0, y + 0, &bl);
            image.getPixelIndex(x + 1, y + 0, &br);

            static const uint8_t subpixels[] = {32,
                126,
                124,
                226,
                123,
                97,
                255,
                236,
                108,
                127,
                225,
                251,
                98,
                252,
                254,
                160};

            bool tlb = !!tl;
            bool trb = !!tr;
            bool blb = !!bl;
            bool brb = !!br;

            int index = (tlb ? 0x1 : 0x0) | (trb ? 0x2 : 0x0) |
                        (blb ? 0x4 : 0x0) | (brb ? 0x8 : 0x0);
            putchar(subpixels[index]);
        }
    }

    return 0;
}
