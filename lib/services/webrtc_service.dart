import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum CallState {
  idle,
  connecting,
  ringing,
  connected,
  ended
}

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  CallState _callState = CallState.idle;
  String? _currentCallUserId;
  Map<String, dynamic>? _currentUser;

  // Callbacks
  Function(CallState)? onCallStateChanged;
  Function(MediaStream)? onRemoteStream;
  Function(String fromId, String fromName, String fromNumber)? onIncomingCall;

  bool get isConnected => _socket?.connected ?? false;
  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false
  };

  Map<String, dynamic>? _incomingOffer;

  Future<void> connect({
    required String serverUrl,
    required Map<String, dynamic> user,
  }) async {
    _currentUser = user;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('✅ Connecté au serveur WebRTC');
      _socket!.emit('register', {'userId': user['id']});
    });

    _socket!.on('registered', (data) {
      print('✅ Enregistré: ${data}');
    });

    _socket!.on('incoming_call', (data) async {
      _currentCallUserId = data['from'].toString();
      _updateCallState(CallState.ringing);
      _incomingOffer = data['offer'];

      if (onIncomingCall != null) {
        onIncomingCall!(
          data['from'].toString(),
          data['fromName'],
          data['fromNumber'],
        );
      }
    });

    _socket!.on('call_answered', (data) async {
      await _handleAnswer(data['answer']);
    });

    _socket!.on('call_rejected', (_) {
      _endCall();
    });

    _socket!.on('call_ended', (_) {
      _endCall();
    });

    _socket!.on('ice_candidate', (data) {
      _addIceCandidate(data['candidate']);
    });

    _socket!.on('call_failed', (data) {
      print('❌ Échec appel: ${data['message']}');
      _endCall();
    });
  }

  Future<void> makeCall(String toUserId) async {
    if (!isConnected) {
      throw Exception('Non connecté au serveur');
    }

    _currentCallUserId = toUserId;
    _updateCallState(CallState.connecting);

    await _createPeerConnection();

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socket!.emit('call', {
      'to': toUserId,
      'offer': offer.toMap(),
      'callerInfo': {
        'id': _currentUser!['id'],
        'numero': _currentUser!['numero'],
        'nom': '${_currentUser!['nom']} ${_currentUser!['prenom'] ?? ''}'.trim(),
      },
    });
  }

  Future<void> answerCall() async {
    if (_incomingOffer == null) {
      throw Exception('Aucun appel entrant');
    }

    _updateCallState(CallState.connecting);
    await _createPeerConnection();

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        _incomingOffer!['sdp'],
        _incomingOffer!['type'],
      ),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socket!.emit('answer', {
      'to': _currentCallUserId,
      'answer': answer.toMap(),
    });

    _incomingOffer = null;
  }

  void rejectCall() {
    _socket!.emit('reject', {'to': _currentCallUserId});
    _currentCallUserId = null;
    _incomingOffer = null;
    _updateCallState(CallState.idle);
  }

  void endCall() {
    if (_currentCallUserId != null) {
      _socket!.emit('end_call', {'to': _currentCallUserId});
    }
    _endCall();
  }

  Future<void> _createPeerConnection() async {

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    if (_localStream != null) {
      print('⚠️ LocalStream déjà créé, on le réutilise');
      return;
    }

    _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
    _peerConnection = await createPeerConnection(_iceServers, _constraints);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _socket!.emit('ice_candidate', {
        'to': _currentCallUserId,
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (onRemoteStream != null) {
          onRemoteStream!(_remoteStream!);
        }
        _updateCallState(CallState.connected);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _updateCallState(CallState.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _endCall();
      }
    };
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  void _addIceCandidate(Map<String, dynamic> candidateMap) {
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateMap['candidate'],
      candidateMap['sdpMid'],
      candidateMap['sdpMLineIndex'],
    );
    _peerConnection?.addCandidate(candidate);
  }

  void _endCall() {
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallUserId = null;

    _updateCallState(CallState.ended);

    Future.delayed(Duration(seconds: 1), () {
      _updateCallState(CallState.idle);
    });
  }

  void _updateCallState(CallState newState) {
    _callState = newState;
    if (onCallStateChanged != null) {
      onCallStateChanged!(newState);
    }
  }

  void dispose() {
    _endCall();
    _socket?.disconnect();
    _socket?.dispose();
  }
}
