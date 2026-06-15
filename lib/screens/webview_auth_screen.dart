import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

enum AuthProvider { google, spotify }

class WebViewAuthScreen extends StatefulWidget {
  final AuthProvider provider;
  const WebViewAuthScreen({super.key, required this.provider});

  @override
  State<WebViewAuthScreen> createState() => _WebViewAuthScreenState();
}

class _WebViewAuthScreenState extends State<WebViewAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _statusText = 'Loading...';
  bool _didComplete = false;

  // ── Spotify OAuth config ─────────────────────────────────────────────────
  // Public Spotify OAuth — no secret needed on client side
  static const String _spotifyClientId = 'spotify_client_id_here'; // TODO: Set your Spotify app client ID
  static const String _spotifyRedirectUri = 'yvlapp://callback';
  static const String _spotifyScope =
      'user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-top-read';

  // ── Google OAuth config ──────────────────────────────────────────────────
  static const String _googleClientId =
      'google_client_id_here.apps.googleusercontent.com'; // TODO: Set your Google OAuth client ID
  static const String _googleRedirectUri = 'com.yourapp.yvl:/oauth2redirect';
  static const String _googleScope = 'email profile openid';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  String get _authUrl {
    if (widget.provider == AuthProvider.spotify) {
      final params = {
        'client_id': _spotifyClientId,
        'response_type': 'token',
        'redirect_uri': _spotifyRedirectUri,
        'scope': _spotifyScope,
        'show_dialog': 'true',
      };
      return Uri.https('accounts.spotify.com', '/authorize', params).toString();
    } else {
      // Google OAuth
      final params = {
        'client_id': _googleClientId,
        'redirect_uri': _googleRedirectUri,
        'response_type': 'code',
        'scope': _googleScope,
        'prompt': 'select_account',
      };
      return Uri.https('accounts.google.com', '/o/oauth2/auth', params).toString();
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() { _isLoading = true; _statusText = 'Loading...'; });
            _handleUrl(url);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (_handleUrl(url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted) setState(() { _isLoading = false; _statusText = 'Error loading page'; });
          },
        ),
      )
      ..loadRequest(Uri.parse(_authUrl));
  }

  /// Returns true if the URL was handled (auth complete), false otherwise.
  bool _handleUrl(String url) {
    if (_didComplete) return false;

    if (widget.provider == AuthProvider.spotify) {
      return _handleSpotifyCallback(url);
    } else {
      return _handleGoogleCallback(url);
    }
  }

  bool _handleSpotifyCallback(String url) {
    // Spotify OAuth implicit flow returns token in fragment
    // e.g. yvlapp://callback#access_token=...&token_type=Bearer&...
    if (!url.contains('access_token=') && !url.contains('callback')) return false;

    try {
      Uri uri;
      try {
        uri = Uri.parse(url);
      } catch (_) {
        return false;
      }

      // Fragment-based token
      String? token;
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final params = Uri.splitQueryString(fragment);
        token = params['access_token'];
      }

      // Query param-based (some implementations)
      token ??= uri.queryParameters['access_token'];

      if (token != null && token.isNotEmpty) {
        _didComplete = true;
        setState(() { _statusText = 'Logging in...'; _isLoading = true; });
        _completeSpotifyLogin(token);
        return true;
      }

      // Error case
      final error = uri.queryParameters['error'];
      if (error != null) {
        _didComplete = true;
        if (mounted) Navigator.of(context).pop(null);
        return true;
      }
    } catch (e) {
      debugPrint('Spotify callback error: $e');
    }
    return false;
  }

  bool _handleGoogleCallback(String url) {
    // Google OAuth code flow
    if (!url.contains('oauth2redirect') && !url.contains('code=')) return false;

    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        _didComplete = true;
        if (mounted) Navigator.of(context).pop(null);
        return true;
      }

      if (code != null && code.isNotEmpty) {
        _didComplete = true;
        setState(() { _statusText = 'Signing in with Google...'; _isLoading = true; });
        _completeGoogleLogin(code);
        return true;
      }
    } catch (e) {
      debugPrint('Google callback error: $e');
    }
    return false;
  }

  Future<void> _completeSpotifyLogin(String token) async {
    try {
      // Fetch Spotify user profile
      final resp = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final name = data['display_name'] as String? ?? 'Spotify User';
        final email = data['email'] as String? ?? '';
        final images = data['images'] as List<dynamic>?;
        final avatar = images != null && images.isNotEmpty
            ? (images.first['url'] as String?)
            : null;

        if (mounted) {
          Navigator.of(context).pop({
            'token': token,
            'name': name,
            'email': email,
            'avatar': avatar,
            'provider': 'spotify',
          });
        }
      } else {
        // Return token only — profile fetch failed
        if (mounted) Navigator.of(context).pop({'token': token, 'provider': 'spotify'});
      }
    } catch (e) {
      debugPrint('Spotify profile fetch error: $e');
      if (mounted) Navigator.of(context).pop({'token': token, 'provider': 'spotify'});
    }
  }

  Future<void> _completeGoogleLogin(String code) async {
    // Exchange code via our backend
    try {
      final resp = await http.post(
        Uri.parse('https://veltrixcode-ytify.hf.space/api/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (mounted) {
          Navigator.of(context).pop({
            'token': token,
            'name': user?['username'] ?? user?['name'] ?? 'Google User',
            'email': user?['email'] ?? '',
            'avatar': user?['avatar'],
            'provider': 'google',
          });
        }
      } else {
        // Fallback: just mark as signed in without backend token
        if (mounted) Navigator.of(context).pop({'provider': 'google'});
      }
    } catch (e) {
      debugPrint('Google token exchange error: $e');
      if (mounted) Navigator.of(context).pop({'provider': 'google'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpotify = widget.provider == AuthProvider.spotify;
    final accentColor = isSpotify ? const Color(0xFF1DB954) : const Color(0xFF4285F4);
    final title = isSpotify ? 'Sign in to Spotify' : 'Sign in with Google';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: accentColor,
                ),
              )
            : null,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && _statusText == 'Logging in...' || _statusText == 'Signing in with Google...')
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: accentColor),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
