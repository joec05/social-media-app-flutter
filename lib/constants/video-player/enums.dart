/// Enum containing the state of the video's audio
enum AudioState{
  mute, unmute
}

/// Enum containing the sources of a video
enum VideoSourceType{
  file, network, asset
}

/// Enum containing the display settings of the duration at the end of the video slider.
/// The duration can be displayed in 2 ways: displaying the video's total duration, or displaying the
/// video's remaining duration.
enum DurationEndDisplay{
  remainingDuration, 
  totalDuration
}