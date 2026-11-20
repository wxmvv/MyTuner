// Declarations for the ptrack module from SoundpipeAudioKit 5.6.1.
// The Watch target supplies the complex transform through Accelerate.
#ifndef WatchSoundpipe_h
#define WatchSoundpipe_h

#include <Accelerate/Accelerate.h>
#include <stddef.h>
#include <stdio.h>

#define SP_OK 1
#define SP_NOT_OK 0

typedef float SPFLOAT;
typedef struct {
    size_t size;
    void *ptr;
} sp_auxdata;

typedef struct {
    int sr;
} sp_data;

typedef struct {
    FFTSetup setup;
    vDSP_Length log2n;
    DSPSplitComplex split;
} sp_fft;

typedef struct {
    SPFLOAT freq, amp;
    SPFLOAT asig, size, peak;
    sp_auxdata signal, prev, sin, spec1, spec2, peakarray;
    int numpks, cnt, histcnt, hopsize;
    SPFLOAT sr, cps, dbs[20], amplo, amphi, npartial, dbfs, prevf;
    sp_fft fft;
} sp_ptrack;

int sp_auxdata_alloc(sp_auxdata *aux, size_t size);
int sp_auxdata_free(sp_auxdata *aux);
void sp_fft_init(sp_fft *fft, int log2n);
void sp_fft_cpx(sp_fft *fft, SPFLOAT *buffer, int count);
void sp_fft_destroy(sp_fft *fft);

int sp_ptrack_create(sp_ptrack **p);
int sp_ptrack_destroy(sp_ptrack **p);
int sp_ptrack_init(sp_data *sp, sp_ptrack *p, int hopSize, int peakCount);
int sp_ptrack_compute(sp_data *sp, sp_ptrack *p, SPFLOAT *input, SPFLOAT *frequency, SPFLOAT *amplitude);

#endif
