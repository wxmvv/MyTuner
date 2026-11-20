#include "WatchPitchTracker.h"
#include "Soundpipe.h"
#include <stdlib.h>

struct WatchPitchTracker {
    sp_data context;
    sp_ptrack *state;
};

WatchPitchTracker *watchPitchTrackerCreate(int sampleRate, int hopSize)
{
    WatchPitchTracker *tracker = calloc(1, sizeof(*tracker));
    if (!tracker) {
        return NULL;
    }
    tracker->context.sr = sampleRate;
    sp_ptrack_create(&tracker->state);
    if (!tracker->state || sp_ptrack_init(&tracker->context, tracker->state, hopSize, 20) != SP_OK) {
        free(tracker->state);
        free(tracker);
        return NULL;
    }
    return tracker;
}

void watchPitchTrackerDestroy(WatchPitchTracker *tracker)
{
    sp_ptrack_destroy(&tracker->state);
    free(tracker);
}

void watchPitchTrackerAnalyze(WatchPitchTracker *tracker, const float *samples, size_t count,
                              float *frequency, float *amplitude)
{
    // ptrack writes cps when it finds a pitch, but otherwise retains its old output.
    // Clear that output so noise cannot supply stale estimates to the smoother.
    tracker->state->cps = 0;
    for (size_t index = 0; index < count; ++index) {
        float sample = samples[index];
        sp_ptrack_compute(&tracker->context, tracker->state, &sample, frequency, amplitude);
    }
}

int sp_auxdata_alloc(sp_auxdata *aux, size_t size)
{
    aux->ptr = calloc(1, size);
    aux->size = size;
    return SP_OK;
}

int sp_auxdata_free(sp_auxdata *aux)
{
    free(aux->ptr);
    return SP_OK;
}

void sp_fft_init(sp_fft *fft, int log2n)
{
    fft->log2n = (vDSP_Length)log2n;
    size_t count = (size_t)1 << log2n;
    fft->setup = vDSP_create_fftsetup(fft->log2n, kFFTRadix2);
    fft->split.realp = calloc(count, sizeof(float));
    fft->split.imagp = calloc(count, sizeof(float));
}

void sp_fft_cpx(sp_fft *fft, SPFLOAT *buffer, int count)
{
    vDSP_ctoz((const DSPComplex *)buffer, 2, &fft->split, 1, (vDSP_Length)count);
    vDSP_fft_zip(fft->setup, &fft->split, 1, fft->log2n, FFT_FORWARD);
    vDSP_ztoc(&fft->split, 1, (DSPComplex *)buffer, 2, (vDSP_Length)count);
}

void sp_fft_destroy(sp_fft *fft)
{
    vDSP_destroy_fftsetup(fft->setup);
    free(fft->split.realp);
    free(fft->split.imagp);
}
