import 'package:web_socket_channel/web_socket_channel.dart';

/// Fallback stub used when no specific platform implementation is available.
WebSocketChannel connectWebSocket(String url) =>
    throw UnsupportedError('No WebSocket implementation for this platform');
