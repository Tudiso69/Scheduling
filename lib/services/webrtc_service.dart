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

  // ✅ Statut en ligne
  Set<int> _onlineUserIds = {};

  // Callbacks
  Function(CallState)? onCallStateChanged;
  Function(MediaStream)? onRemoteStream;
  Function(String fromId, String fromName, String fromNumber)? onIncomingCall;
  Function(Set<int>)? onOnlineUsersChanged;

  bool get isConnected => _socket?.connected ?? false;
  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  Set<int> get onlineUserIds => _onlineUserIds;
  IO.Socket? get socket => _socket;

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
    String? token,
  }) async {
    print('🔌 === CONNEXION WEBRTC ===');
    print('🌐 URL: $serverUrl');
    print('👤 User: ${user['id']} - ${user['nom']}');

    _currentUser = user;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('✅ Socket connecté !');
      print('📡 Socket ID: ${_socket!.id}');

      _socket!.emit('register', {
        'userId': user['id'],
        'token': token,
      });
    });

    _socket!.on('disconnect', (_) {
      print('❌ Socket déconnecté');
      _onlineUserIds.clear();
      _notifyOnlineUsersChanged();
    });

    _socket!.on('connect_error', (error) {
      print('❌ Erreur connexion: $error');
    });

    _socket!.on('registered', (data) {
      print('✅ Enregistrement confirmé: $data');
    });

    // ✅ AMÉLIORATION: Meilleure gestion des mises à jour de statut
    _socket!.on('users_status_update', (data) {
      print('👥 === BROADCAST STATUT REÇU ===');
      print('📦 Data complète: $data');

      try {
        if (data == null) {
          print('⚠️  Data est null');
          return;
        }

        if (data is Map) {
          final onlineIdsData = data['onlineUserIds'];
          print('🆔 onlineUserIds dans data: $onlineIdsData');

          if (onlineIdsData == null) {
            print('⚠️  onlineUserIds est null');
            return;
          }

          // ✅ Conversion robuste
          final List<int> newOnlineIds = [];
          if (onlineIdsData is List) {
            for (var id in onlineIdsData) {
              if (id is int) {
                newOnlineIds.add(id);
              } else if (id is String) {
                newOnlineIds.add(int.parse(id));
              } else {
                newOnlineIds.add(int.parse(id.toString()));
              }
            }
          }

          _onlineUserIds = newOnlineIds.toSet();
          print('✅ ${_onlineUserIds.length} users en ligne mis à jour');
          print('🆔 Liste des IDs: $_onlineUserIds');

          // ✅ Notifier les listeners
          _notifyOnlineUsersChanged();

        } else {
          print('⚠️  Data n\'est pas une Map: ${data.runtimeType}');
        }
      } catch (e, stackTrace) {
        print('❌ Erreur parsing users online: $e');
        print('Stack trace: $stackTrace');
      }
    });

    _socket!.on('incoming_call', (data) async {
      print('📞 Appel entrant de ${data['fromName']}');
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
      print('✅ Appel accepté');
      await _handleAnswer(data['answer']);
    });

    _socket!.on('call_rejected', (_) {
      print('❌ Appel rejeté');
      _endCall();
    });

    _socket!.on('call_ended', (_) {
      print('📴 Appel terminé par l\'autre partie');
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

  // ✅ AMÉLIORATION: Méthode dédiée pour notifier les changements
  void _notifyOnlineUsersChanged() {
    if (onOnlineUsersChanged != null) {
      print('📢 Notification des listeners...');
      onOnlineUsersChanged!(_onlineUserIds);
      print('✅ Listeners notifiés');
    } else {
      print('⚠️  Aucun listener enregistré');
    }
  }

  // ✅ Vérifier si un utilisateur est en ligne
  bool isUserOnline(int userId) {
    final isOnline = _onlineUserIds.contains(userId);
    print('🔍 User $userId en ligne ? $isOnline');
    return isOnline;
  }

  Future<void> makeCall(String toUserId) async {
    if (!isConnected) {
      throw Exception('Non connecté au serveur');
    }

    print('📞 Appel vers $toUserId');
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

    print('✅ Acceptation de l\'appel');
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
    print('❌ Rejet de l\'appel');
    _socket!.emit('reject', {'to': _currentCallUserId});
    _currentCallUserId = null;
    _incomingOffer = null;
    _updateCallState(CallState.idle);
  }

  void endCall() {
    print('📴 Fin de l\'appel');
    if (_currentCallUserId != null) {
      _socket!.emit('end_call', {'to': _currentCallUserId});
    }
    _endCall();
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) {
      print('⚠️ Une peer connection existe déjà, nettoyage...');
      await _peerConnection!.close();
      _peerConnection!.dispose();
      _peerConnection = null;
    }

    if (_localStream != null) {
      print('⚠️ Un stream local existe déjà, nettoyage...');
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      _localStream!.dispose();
      _localStream = null;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Permission microphone non accordée');
    }

    print('🎤 Création du nouveau stream audio...');
    _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);

    print('📡 Création de la nouvelle peer connection...');
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
      print('📡 État connexion: $state');
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
    print('🧹 Nettoyage des ressources WebRTC...');

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      _localStream!.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream!.dispose();
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      _peerConnection!.close();
      _peerConnection!.dispose();
      _peerConnection = null;
    }

    _currentCallUserId = null;
    _incomingOffer = null;

    _updateCallState(CallState.ended);

    Future.delayed(Duration(seconds: 1), () {
      _updateCallState(CallState.idle);
      print('✅ Nettoyage terminé, prêt pour un nouvel appel');
    });
  }

  void _updateCallState(CallState newState) {
    _callState = newState;
    if (onCallStateChanged != null) {
      onCallStateChanged!(newState);
    }
  }

  void dispose() {
    print('🗑️ Dispose WebRTCService');
    _endCall();
    _socket?.disconnect();
    _socket?.dispose();
    _onlineUserIds.clear();
  }
}
