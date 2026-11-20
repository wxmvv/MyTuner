#ifndef WatchPitchTracker_h
#define WatchPitchTracker_h

#include <stddef.h>

typedef struct WatchPitchTracker WatchPitchTracker;

WatchPitchTracker *watchPitchTrackerCreate(int sampleRate, int hopSize);
void watchPitchTrackerDestroy(WatchPitchTracker *tracker);
void watchPitchTrackerAnalyze(WatchPitchTracker *tracker, const float *samples, size_t count,
                              float *frequency, float *amplitude);

#endif
