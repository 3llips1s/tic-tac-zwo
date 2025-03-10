import 'dart:convert';

enum MessageType {
  cellSelection,
  articleSelection,
  disconnect,
  reconnect,
  gameState,
  playerNames,
  ready,
  readyConfirm,
  rematch,
}

class GameMessage {
  final MessageType type;
  final dynamic payload;

  GameMessage({required this.type, required this.payload});

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'payload': payload,
    };
  }

  factory GameMessage.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return GameMessage(
        type: MessageType.values.firstWhere((e) => e.name == data['type']),
        payload: data['payload']);
  }
}
