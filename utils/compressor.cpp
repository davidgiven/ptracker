/* This is a hacked-up port of garfield's port of Tricky's compressor from here:
 * https://www.stardot.org.uk/forums/viewtopic.php?p=333389&hilit=compressor#p333389
 */

#define _CRT_SECURE_NO_WARNINGS
#include <memory.h>
#include <stdio.h>
#include <string.h>

typedef unsigned char byte;

int max(int a, int b)
{
    return a > b ? a : b;
}
int min(int a, int b)
{
    return a < b ? a : b;
}

const size_t MAX_FILE_SIZE = 0x10000;
byte original_data[MAX_FILE_SIZE], compressed_data[MAX_FILE_SIZE] = {0},
                                   decompressed_data[MAX_FILE_SIZE] = {0};
int original_size = 0, compressed_size = 0, decompressed_size = 0;

void decompress(void)
{
    decompressed_size = 0;
    for (int src = 0; compressed_data[src]; ++src)
    {
        if (compressed_data[src] & 0x80) // offset:len
        {
            int len = (compressed_data[src++] & 0x7f) + 2;
            int off = decompressed_size - 256 + compressed_data[src];
            while (len--)
            {
                decompressed_data[decompressed_size++] =
                    decompressed_data[off++];
            }
        }
        else // raw
        {
            int len = compressed_data[src] & 0x7f;
            while (len--)
            {
                decompressed_data[decompressed_size++] = compressed_data[++src];
            }
        }
    }
    if (decompressed_size != original_size ||
        0 != memcmp(original_data, decompressed_data, decompressed_size))
        printf("compress+decompress failed\n");
}

int find_best_seq(int& from, int dst, int max_offset, int max_seq_len)
{
    int best = 0;
    for (int src = max(dst - max_offset, 0); src < dst; ++src)
    {
        for (int num = 0; num <= min(original_size - dst, max_seq_len); ++num)
        {
            if (original_data[src + num] != original_data[dst + num])
                break;
            if (num > best)
            {
                from = src;
                best = num;
            }
        }
    }
    return best;
}

void compress(void)
{
    compressed_size = 0;
    int max_offset = 256, max_seq_len = 127 + 2, cost = 2;
    int raw_copy_len = 0, raw_len_addr = 0;
    for (int dst = 0; dst < original_size; dst)
    {
        int src = 0, best = find_best_seq(src, dst, max_offset, max_seq_len);
        if (best >= cost + !!raw_copy_len) // make sure to at least break even
                                           // if a RAW is open
        {
            if (raw_copy_len)
            {
                compressed_data[raw_len_addr] = raw_copy_len;
                raw_copy_len = 0;
            }
            compressed_data[compressed_size++] = best - 2 | 0x80;
            compressed_data[compressed_size++] = src - dst + 0x100;
            dst += best;
        }
        else
        {
            if (raw_copy_len == 127) // max RAW copy len
            {
                compressed_data[raw_len_addr] = raw_copy_len;
                raw_copy_len = 0;
            }
            if (!raw_copy_len)
            {
                raw_len_addr = compressed_size++;
            }
            compressed_data[compressed_size++] = original_data[dst++];
            ++raw_copy_len;
        }
    }
    if (raw_copy_len)
    {
        compressed_data[raw_len_addr] = raw_copy_len;
        raw_copy_len = 0;
    }
    compressed_data[compressed_size++] = 0; // terminator
}

int process()
{
    byte* ptr = original_data;
    for (;;)
    {
        int c = getchar();
        if (c == EOF)
            break;
        *ptr++ = c;
    }
    original_size = ptr - original_data;

    compress();
    decompress();

    if (decompressed_size != original_size ||
        0 != memcmp(original_data, decompressed_data, decompressed_size))
    {
        fprintf(stderr, "decompress failed\n");
        return -2;
    }

    printf("; compressed data: original=%u, compressed=%u, ratio=%d%%",
        original_size,
        compressed_size,
        100 * compressed_size / original_size);
    for (int b = 0; b < compressed_size; ++b)
    {
        if (b & 63)
            printf(", 0x%02X",
                compressed_data[b]); // split lines after 64 bytes - just
                                     // prettier
        else
            printf("\n.byte 0x%02X", compressed_data[b]);
    }
    return 0;
}

int main(int argc, char* argv[])
{
    return process();
}
