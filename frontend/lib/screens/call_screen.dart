import 'package:flutter/material.dart';
import '../services/agora_service.dart';
import '../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final SocketService socketService;
  final String remoteUserId;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.socketService,
    required this.remoteUserId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final AgoraService _agoraService = AgoraService();
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      await _agoraService.initAgora();
      await _agoraService.joinChannel(widget.channelId, "");
      if (mounted) setState(() => _localUserJoined = true);
    } catch (e) {
      print("Call init error: $e");
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraService.engine.muteLocalAudioStream(_isMuted);
  }

  @override
  void dispose() {
    _agoraService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            left: -80,
            child: CircleAvatar(radius: 200, backgroundColor: Colors.greenAccent.withOpacity(0.06)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 2),
                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 40)],
                  ),
                  child: const Icon(Icons.person, size: 80, color: Colors.white54),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.remoteUserId.length > 10
                      ? widget.remoteUserId.substring(0, 10) + '...'
                      : widget.remoteUserId,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _localUserJoined ? "● ON CALL" : "CONNECTING...",
                  style: TextStyle(
                    color: _localUserJoined ? Colors.greenAccent : Colors.white38,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callBtn(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.redAccent : Colors.white24,
                  onTap: _toggleMute,
                ),
                _callBtn(
                  icon: Icons.call_end,
                  color: Colors.redAccent,
                  size: 65,
                  onTap: () {
                    _agoraService.leaveChannel();
                    Navigator.pop(context);
                  },
                ),
                _callBtn(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                  color: _isSpeakerOn ? Colors.greenAccent.withOpacity(0.3) : Colors.white24,
                  onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _callBtn({required IconData icon, required Color color, double size = 55, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
