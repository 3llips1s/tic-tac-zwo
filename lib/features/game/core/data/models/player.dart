import 'dart:ui';

import 'package:tic_tac_zwo/config/game_config/constants.dart';

import '../../../../../config/game_config/config.dart';

class Player {
  final String userName;
  PlayerSymbol symbol;
  String? userId;
  String? countryCode;
  final bool isAI;

  Player({
    required this.userName,
    required this.symbol,
    this.isAI = false,
    this.countryCode,
    this.userId,
  });

  String get symbolString => symbol == PlayerSymbol.X ? 'X' : 'Ö';
  Color get symbolColor =>
      symbol == PlayerSymbol.X ? colorRed : colorYellowAccent;

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'symbol': symbol.index,
      'isAI': isAI,
      'user_id': userId,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      userName: json['userName'],
      symbol: PlayerSymbol.values[json['symbol']],
      isAI: json['isAI'] ?? false,
      userId: json['user_id'] ?? '',
    );
  }
}
