import 'package:modulearn/features/modulation/domain/entities/audio_recording.dart';

abstract class AudioRepository {
  /// Starts recording audio
  Future<void> startRecording();

  /// Pauses the current recording
  Future<void> pauseRecording();

  /// Resumes the paused recording
  Future<void> resumeRecording();

  /// Stops the current recording and saves it
  Future<AudioRecording> stopRecording();

  /// Cancels the current recording and discards the audio
  Future<void> cancelRecording();

  /// Gets all saved recordings
  Future<List<AudioRecording>> getAllRecordings();

  /// Plays a specific recording
  Future<void> playRecording(String id);

  /// Pauses the current playback
  Future<void> pausePlayback();

  /// Resumes the paused playback
  Future<void> resumePlayback();

  /// Stops playback
  Future<void> stopPlayback();

  /// Deletes a recording
  Future<bool> deleteRecording(String id);

  /// Checks if recording permission is granted
  Future<bool> hasPermission();

  /// Requests permission to record audio
  Future<bool> requestPermission();

  /// Converts an audio recording to binary representation for modulation
  Future<String> convertAudioToBinary(String id);
}
