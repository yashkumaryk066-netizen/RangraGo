import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config.dart';

class AgoraService {
  late RtcEngine engine;
  final String appId = AppConfig.agoraAppId;


  Future<void> initAgora() async {
    // Retrieve permissions
    await [Permission.microphone].request();

    // Create the engine
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // AUDIO ENABLE KAREIN (Zaroori hai)
    await engine.enableAudio();
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    // Register event handlers
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("Local user joined: ${connection.localUid}");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("Remote user joined: $remoteUid");
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print("Remote user offline: $remoteUid");
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print("Left channel");
        },
      ),
    );
  }

  Future<void> joinChannel(String channelId, String token) async {
    await engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
  }
}
