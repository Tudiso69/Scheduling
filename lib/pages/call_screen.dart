import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../services/api_service.dart';

class CallScreen extends StatefulWidget {
  final WebRTCService? webrtcService;
  final String? destinationUserId;
  final String? destinationName;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    this.webrtcService,
    this.destinationUserId,
    this.destinationName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRTCService _webrtcService;
  String _statusText = '';
  bool _isMuted = false;

  DateTime? _callStartTime;
  DateTime? _callEndTime;
  String _callStatus = 'failed';
  bool _callHistorySaved = false;

  @override
  void initState() {
    super.initState();
    _webrtcService = widget.webrtcService ?? WebRTCService();
    _setupCallbacks();

    _callStartTime = DateTime.now();

    if (widget.isIncoming) {
      _statusText = 'Appel entrant...';
      _callStatus = 'incoming';
    } else {
      _statusText = 'Appel sortant...';
      _callStatus = 'outgoing';
      _initiateCall();
    }
  }

  void _setupCallbacks() {
    _webrtcService.onCallStateChanged = (state) {
      if (!mounted) return;

      setState(() {
        switch (state) {
          case CallState.connecting:
            _statusText = 'Connexion...';
            break;
          case CallState.ringing:
            _statusText = 'Sonnerie...';
            break;
          case CallState.connected:
            _statusText = 'En communication';
            _callStatus = 'completed';
            if (_callStartTime == null) {
              _callStartTime = DateTime.now();
            }
            break;
          case CallState.ended:
            _statusText = 'Appel terminé';
            _callEndTime = DateTime.now();
            _saveCallHistory();
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
            break;
          default:
            break;
        }
      });
    };
  }

  Future<void> _initiateCall() async {
    try {
      await _webrtcService.makeCall(widget.destinationUserId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Erreur: $e';
        _callStatus = 'failed';
      });
    }
  }

  Future<void> _saveCallHistory() async {
    if (_callHistorySaved) return;
    _callHistorySaved = true;

    final duration = _callEndTime != null && _callStartTime != null
        ? _callEndTime!.difference(_callStartTime!).inSeconds
        : 0;

    String finalStatus;
    if (_callStatus == 'completed' && duration > 0) {
      finalStatus = 'completed';
    } else if (_callStatus == 'incoming' || _callStatus == 'outgoing') {
      finalStatus = 'no_answer';
    } else {
      finalStatus = 'failed';
    }

    try {
      final receiverId = int.tryParse(widget.destinationUserId ?? '0');
      if (receiverId == null || receiverId == 0) return;

      print('📝 Sauvegarde de l\'historique: $finalStatus, durée: ${duration}s');

      final result = await ApiService.saveCallHistory(
        receiverId: receiverId,
        callStatus: finalStatus,
        durationSeconds: duration,
        startedAt: _callStartTime ?? DateTime.now(),
        endedAt: _callEndTime,
      );

      if (result['success']) {
        print('✅ Historique sauvegardé avec succès');
      } else {
        print('❌ Échec sauvegarde historique: ${result['message']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde historique: $e');
    }
  }

  void _handleReject() {
    _callStatus = 'rejected';
    _callEndTime = DateTime.now();
    _webrtcService.rejectCall();
    _saveCallHistory();
    Navigator.pop(context);
  }

  void _handleEndCall() {
    _callEndTime = DateTime.now();
    _webrtcService.endCall();
    _saveCallHistory();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 50),
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  widget.destinationName ?? 'Inconnu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _statusText,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                if (_webrtcService.callState == CallState.connected && _callStartTime != null)
                  _buildCallTimer(),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(40),
              child: widget.isIncoming &&
                  _webrtcService.callState == CallState.ringing
                  ? _buildIncomingCallButtons()
                  : _buildActiveCallButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTimer() {
    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1)),
      builder: (context, snapshot) {
        if (_callStartTime == null) return SizedBox.shrink();

        final duration = DateTime.now().difference(_callStartTime!);
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '$minutes:$seconds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingCallButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.red,
          size: 70,
          onPressed: _handleReject,
        ),
        _buildCallButton(
          icon: Icons.call,
          color: Colors.green,
          size: 70,
          onPressed: () async {
            await _webrtcService.answerCall();
          },
        ),
      ],
    );
  }

  Widget _buildActiveCallButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: _isMuted ? Colors.red : Colors.white,
          onPressed: () {
            setState(() {
              _isMuted = !_isMuted;
              _webrtcService.localStream?.getAudioTracks()[0].enabled =
              !_isMuted;
            });
          },
        ),
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.red,
          size: 70,
          onPressed: _handleEndCall,
        ),
        _buildCallButton(
          icon: Icons.volume_up,
          color: Colors.white,
          onPressed: () {
            Helper.setSpeakerphoneOn(true);
          },
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: size * 0.5,
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    if (_webrtcService.callState != CallState.idle &&
        _webrtcService.callState != CallState.ended) {
      _callEndTime = DateTime.now();
      _callStatus = 'cancelled';
      _saveCallHistory();
      _webrtcService.endCall();
    }
    super.dispose();
  }
}
