import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String? destinationUserId;
  final String? destinationName;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    this.destinationUserId,
    this.destinationName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  String _statusText = '';
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();

    if (widget.isIncoming) {
      _statusText = 'Appel entrant...';
    } else {
      _initiateCall();
    }
  }

  void _setupCallbacks() {
    _webrtcService.onCallStateChanged = (state) {
      if (!mounted) return; // ✅ Vérifier si le widget est toujours monté

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
            break;
          case CallState.ended:
            _statusText = 'Appel terminé';
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
      });
    }
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

  Widget _buildIncomingCallButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.red,
          size: 70,
          onPressed: () {
            _webrtcService.rejectCall();
            Navigator.pop(context);
          },
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
          onPressed: () {
            _webrtcService.endCall();
            Navigator.pop(context);
          },
        ),
        _buildCallButton(
          icon: Icons.volume_up,
          color: Colors.white,
          onPressed: () {
            // Toggle speaker
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

  // ✅ MÉTHODE DISPOSE CORRIGÉE
  @override
  void dispose() {
    // Nettoyer seulement si l'appel est toujours actif
    if (_webrtcService.callState != CallState.idle &&
        _webrtcService.callState != CallState.ended) {
      print('🧹 Nettoyage depuis CallScreen dispose');
      _webrtcService.endCall();
    }
    super.dispose();
  }
}
