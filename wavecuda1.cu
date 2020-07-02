#include <cstdlib>
#include <sys/time.h>
#include <math.h>

#include <stdio.h>
#include <assert.h>

void writeBMP(const int x, const int y, const unsigned char* const bmp, const char* const name) {
  const unsigned char bmphdr[54] = {66, 77, 255, 255, 255, 255, 0, 0, 0, 0, 54, 4, 0, 0, 40, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 1, 0, 8, 0, 0, 0, 0, 0, 255, 255, 255, 255, 196, 14, 0, 0, 196, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  unsigned char hdr[1078];
  int i, j, c, xcorr, diff;
  FILE* f;

  xcorr = (x + 3) >> 2 << 2;  // BMPs have to be a multiple of 4 pixels wide
  diff = xcorr - x;

  for (i = 0; i < 54; i++) hdr[i] = bmphdr[i];
  *((int*)(&hdr[18])) = xcorr;
  *((int*)(&hdr[22])) = y;
  *((int*)(&hdr[34])) = xcorr * y;
  *((int*)(&hdr[2])) = xcorr * y + 1078;
  for (i = 0; i < 256; i++) { 
    j = i * 4 + 54;
    hdr[j+0] = i;  // blue ColorTable
    hdr[j+1] = 0;  // green
    hdr[j+2] = 0;  // red
    hdr[j+3] = 0;  // dummy
  }

  f = fopen(name, "wb");  assert(f != NULL);
  c = fwrite(hdr, 1, 1078, f);  assert(c == 1078);
  if (diff == 0) {
    c = fwrite(bmp, 1, x * y, f);  assert(c == x * y);
  } else {
    *((int*)(&hdr[0])) = 0;  // need up to three zero bytes
    for (j = 0; j < y; j++) {
      c = fwrite(&bmp[j * x], 1, x, f);  assert(c == x);
      c = fwrite(hdr, 1, diff, f);  assert(c == diff);
    }
  }
  fclose(f);
}

int main(int argc, char *argv[]) {

    // check command line
    if (argc != 3) {
        fprintf(stderr, "usage: %s frame_width num_frames\n", argv[0]);
        exit(-1);
    }
    int width = atoi(argv[1]);
    if (width < 100) {
        fprintf(stderr, "error: frame_width must be at least 100\n");
        exit(-1);
    }
    int frames = atoi(argv[2]);
    if (frames < 1) {
        fprintf(stderr, "error: num_frames must be at least 1\n");
        exit(-1);
    }
    printf("computing %d frames of %d by %d picture\n", frames, width, width);

    // allocate picture array
    unsigned char *pic = new unsigned char[frames * width * width];

    // start time
    timeval start, end;
    gettimeofday(&start, NULL);

    for (int frame = 0; frame < frames; frame++) {
        for (int row = 0; row < width; row++) {
            for (int col = 0; col < width; col++) {
                float fx = col - 1024 / 2;
                float fy = row - 1024 / 2;
                float d = sqrtf(fx * fx + fy * fy);
                unsigned char color = (unsigned char)(160.0f + 127.0f *
                                                                   cos(d / 10.0f - frame / 7.0f) /
                                                                   (d / 50.0f + 1.0f));

                pic[frame * width * width + row * width + col] = (unsigned char)color;
            }
        }
    }

    // end time
    gettimeofday(&end, NULL);
    double runtime = end.tv_sec + end.tv_usec / 1000000.0 - start.tv_sec - start.tv_usec / 1000000.0;
    printf("compute time: %.4f s\n", runtime);

    // verify result by writing frames to BMP files
    if ((width <= 256) && (frames <= 100)) {
        for (int frame = 0; frame < frames; frame++) {
            char name[32];
            sprintf(name, "wave%d.bmp", frame + 1000);
            writeBMP(width, width, &pic[frame * width * width], name);
        }
    }

    delete[] pic;
    return 0;
}
