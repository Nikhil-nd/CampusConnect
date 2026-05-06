import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBannerShell extends StatefulWidget {
  const OfflineBannerShell({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineBannerShell> createState() => _OfflineBannerShellState();
}

class _OfflineBannerShellState extends State<OfflineBannerShell> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollTimer;
  int _checkGeneration = 0;
  bool _isOffline = false;
  int _offlineStreak = 0;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      unawaited(_updateConnectivity(results));
    });
  }

  Future<bool> _hasInternetRoute() async {
    // Use multiple signals because some networks block specific IPs (1.1.1.1/8.8.8.8)
    // and some devices briefly report `ConnectivityResult.none` while still online.
    const Duration socketTimeout = Duration(seconds: 2);
    const Duration httpTimeout = Duration(seconds: 3);

    // 1) TCP connect to well-known IPs (DNS-free).
    const List<(String, int)> ipEndpoints = <(String, int)>[
      ('1.1.1.1', 443),
      ('8.8.8.8', 53),
    ];

    for (final (String host, int port) in ipEndpoints) {
      Socket? socket;
      try {
        socket = await Socket.connect(host, port, timeout: socketTimeout);
        return true;
      } catch (_) {
        // Try next endpoint.
      } finally {
        try {
          socket?.destroy();
        } catch (_) {}
      }
    }

    // 2) TCP connect via DNS (often succeeds when IP endpoints are blocked).
    for (final String host in <String>['google.com', 'firebase.google.com']) {
      Socket? socket;
      try {
        socket = await Socket.connect(host, 443, timeout: socketTimeout);
        return true;
      } catch (_) {
        // Try next host.
      } finally {
        try {
          socket?.destroy();
        } catch (_) {}
      }
    }

    // 3) Lightweight HTTPS probe (handles some captive portals better).
    final HttpClient client = HttpClient()..connectionTimeout = httpTimeout;
    try {
      final Uri uri = Uri.parse('https://www.google.com/generate_204');
      final HttpClientRequest request = await client.getUrl(uri).timeout(httpTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final HttpClientResponse response = await request.close().timeout(httpTimeout);
      await response.drain<void>();

      return response.statusCode == HttpStatus.noContent ||
          (response.statusCode >= 200 && response.statusCode < 400);
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _setOffline(bool nextOffline) {
    if (!mounted || nextOffline == _isOffline) {
      return;
    }

    setState(() {
      _isOffline = nextOffline;
    });

    if (nextOffline) {
      _startPollingWhileOffline();
    } else {
      _stopPolling();
    }
  }

  void _startPollingWhileOffline() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
        await _updateConnectivity(results);
      } catch (_) {
        // Keep existing state; polling will try again.
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _updateConnectivity(List<ConnectivityResult> results) async {
    final int generation = ++_checkGeneration;

    final bool hasNetworkType = results.isNotEmpty &&
        results.any((ConnectivityResult result) => result != ConnectivityResult.none);

    // If Android reports some transport (wifi/mobile/vpn/etc), treat as online.
    // This avoids false-offline on devices that block probes.
    if (hasNetworkType) {
      if (!mounted || generation != _checkGeneration) {
        return;
      }

      _offlineStreak = 0;
      _setOffline(false);
      return;
    }

    // If Android reports none, double-check route before showing the banner.
    final bool hasRoute = await _hasInternetRoute();
    if (!mounted || generation != _checkGeneration) {
      return;
    }

    if (hasRoute) {
      _offlineStreak = 0;
      _setOffline(false);
      return;
    }

    // Debounce: require 2 consecutive failures before showing the banner.
    _offlineStreak = (_offlineStreak + 1).clamp(0, 3);
    if (_isOffline || _offlineStreak >= 2) {
      _setOffline(true);
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      await _updateConnectivity(results);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _setOffline(false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: widget.child),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: _isOffline ? 0 : -84,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.wifi_off_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No internet connection. Browse content already on screen, and retry actions when you are back online.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
