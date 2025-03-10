import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/game_message.dart';

class PairService {
  static const connectionTimeout = Duration(seconds: 30);

  final NearbyService _nearbyService = NearbyService();
  StreamController<GameMessage> _messageController =
      StreamController.broadcast();
  final _discoveredDevicesStream = StreamController<List<Device>>.broadcast();
  final _connectionStateStream = StreamController<ConnectionState>.broadcast();

  List<Device> _devices = [];
  Device? _connectedDevice;
  StreamSubscription? _stateChangeSubscription;
  Timer? _connectionTimer;
  bool _isHost = false;
  String? _localDeviceName;
  bool _isDisposed = false;

  late Function(Device) onDeviceConnected = (device) {};
  late Function() onDeviceDisconnected = () {};

  Stream<GameMessage> get messages => _messageController.stream;
  Stream<List<Device>> getDiscoveredDevicesStream() =>
      _discoveredDevicesStream.stream;

  bool get isHost => _isHost;

  void setAsHost(bool isHost) {
    _isHost = isHost;
  }

  String _formatDeviceName(String name) {
    final parts = name.split(RegExp(r'[ _-]'));
    String firstPart = parts.first.trim();

    if (firstPart.isNotEmpty) {
      firstPart =
          firstPart[0].toUpperCase() + firstPart.substring(1).toLowerCase();
    }

    if (firstPart.length > 9) {
      firstPart = firstPart.substring(0, 9);
    }

    return firstPart.isEmpty ? 'Unbekanntes' : firstPart;
  }

  Future<String> getLocalDeviceName() async {
    if (_localDeviceName == null) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _localDeviceName = _formatDeviceName(androidInfo.model);
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _localDeviceName = _formatDeviceName(iosInfo.name);
        }
      } catch (e) {
        print('error getting local device name: $e');
        _localDeviceName = 'Spieler';
      }
    }

    return _localDeviceName ?? 'Spieler';
  }

  String? getConnectedDeviceName() {
    return _connectedDevice != null
        ? _formatDeviceName(_connectedDevice!.deviceName)
        : 'Gegner*in';
  }

  Future<void> initNearbyService() async {
    await _requestPermissions();

    _stateChangeSubscription?.cancel();
    _stateChangeSubscription = null;

    await _nearbyService.init(
      serviceType: 'mp-connection',
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) {
        if (isRunning) {
          startDiscovery();
          _nearbyService.startAdvertisingPeer();
        }
      },
    );

    // single state change subscription
    _stateChangeSubscription = _nearbyService.stateChangedSubscription(
      callback: (devices) {
        _devices = devices;
        _discoveredDevicesStream.add(List.from(_devices));

        // check for new connections
        for (var device in devices) {
          if (device.state == SessionState.connected &&
              (_connectedDevice == null ||
                  _connectedDevice?.deviceId != device.deviceId)) {
            _connectedDevice = device;
            if (!isHost) setAsHost(false);
            print('connected to device: ${device.deviceName}');

            onDeviceConnected(device);
          }
        }

        if (_connectedDevice != null &&
            !devices.any((d) =>
                d.deviceId == _connectedDevice?.deviceId &&
                d.state == SessionState.connected)) {
          print('device disconnected: ${_connectedDevice?.deviceName}');
          _connectedDevice = null;

          onDeviceDisconnected();
        }
      },
    );
  }

  Future<void> startDiscovery() async {
    _devices.clear();
    _discoveredDevicesStream.add([]);

    _nearbyService.startBrowsingForPeers();
    _nearbyService.stateChangedSubscription(
      callback: (devices) {
        _devices = devices;
        _discoveredDevicesStream.add(List.from(_devices));
        print('discovered devices: $devices');
      },
    );
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.nearbyWifiDevices] != PermissionStatus.granted) {
      print("Error: Required permissions not granted!");
    }
  }

  Future<void> connectToDevice(Device device) async {
    if (_isDisposed) return;

    if (_devices.any((d) =>
        d.deviceId == device.deviceId && d.state == SessionState.connected)) {
      print(
          "⚠️ Already connected to ${device.deviceName}, skipping reconnection.");
      onDeviceConnected(device);
      return; // 🔥 Prevent duplicate connections
    }

    setAsHost(true);

    print('attempting to connect to ${device.deviceName}');

    _connectionTimer?.cancel();
    _connectionTimer = Timer(
      connectionTimeout,
      () {
        if (_connectedDevice?.deviceId != device.deviceId) {
          _connectionStateStream.add(ConnectionState.timeout);
        }
      },
    );

    try {
      await _nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );

      _nearbyService.stateChangedSubscription(
        callback: (devices) {
          for (var d in devices) {
            if (d.state == SessionState.connected &&
                d.deviceId == device.deviceId) {
              print('connected to ${device.deviceName}');

              onDeviceConnected(d);
            }
          }
        },
      );
    } catch (e) {
      print('failed to connect to ${device.deviceName}: $e');
    }
  }

  Future<void> reconnect() async {
    if (_connectedDevice != null) {
      await connectToDevice(_connectedDevice!);
    }
  }

  Future<void> sendMessage(GameMessage message) async {
    String jsonMessage = jsonEncode(message.toJson());
    for (var device in _devices) {
      _nearbyService.sendMessage(device.deviceId, jsonMessage);
    }
  }

  void receiveMessage(String jsonMessage) {
    final GameMessage message = GameMessage.fromJson(jsonMessage);
    _messageController.add(message);
  }

  void dispose() {
    _isDisposed = true;
    _connectionTimer?.cancel();
    _stateChangeSubscription?.cancel();
    _nearbyService.stopBrowsingForPeers();
    _messageController.close();
    _discoveredDevicesStream.close();
    _connectionStateStream.close();
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  timeout,
  reconnecting,
}

final pairServiceProvider = Provider<PairService>(
  (ref) {
    return PairService();
  },
);
