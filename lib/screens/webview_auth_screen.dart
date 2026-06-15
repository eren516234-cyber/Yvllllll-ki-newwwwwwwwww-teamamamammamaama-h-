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
  bool _didComplete = false;

  // Spotify — implicit grant (no backend secret needed)
  // Replace with your Spotify Developer Dashboard client_id:
  // https://developer.spotify.com/dashboard
  static const _spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
  // This redirect URI must be whitelisted in your Spotify app settings:
  static const _spotifyRedirectUri = 'https://veltrixcode-ytify.hf.space/callback/spotify';
  static const _spotifyScope =
      'user-read-private user-read-email playlist-read-private '
      'playlist-read-collaborative user-library-read user-top-read';

  String get _authUrl {
    if (widget.provider == AuthProvider.spotify) {
      final p = {
        'client_id': _spotifyClientId,
        'response_type': 'token',
        'redirect_uri': _spotifyRedirectUri,
        'scope': _spotifyScope,
        'show_dialog': 'true',
      };
      return Uri.https('accounts.spotify.com', '/authorize', p).toString();
    } else {
      // Google — use backend-managed credentials
      final p = {
        'client_id': '764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com',
        'redirect_uri': 'https://veltrixcode-ytify.hf.space/auth/google/callback',
        'response_type': 'code',
        'scope': 'email profile openid',
        'prompt': 'select_account',
      };
      return Uri.https('accounts.google.com', '/o/oauth2/auth', p).toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _isLoading = true);
          _handleUrl(url);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _isLoading = false);
          // Also pull href from JS (catches fragment-based redirects)
          _controller
              .runJavaScriptReturningResult('window.location.href')
              .then((v) => _handleUrl(v.toString().replaceAll('"', '')))
              .catchError((_) {});
        },
        onNavigationRequest: (req) {
          if (_handleUrl(req.url)) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _isLoading = false);
          _controller.currentUrl().then((u) { if (u != null) _handleUrl(u); }).catchError((_) {});
        },
      ))
      ..loadRequest(Uri.parse(_authUrl));
  }

  bool _handleUrl(String url) {
    if (_didComplete) return false;
    return widget.provider == AuthProvider.spotify
        ? _onSpotifyUrl(url)
        : _onGoogleUrl(url);
  }

  bool _onSpotifyUrl(String url) {
    if (!url.contains('access_token')) return false;
    try {
      String? token;
      if (url.contains('#')) {
        final frag = url.split('#').last;
        token = Uri.splitQueryString(frag)['access_token'];
      }
      token ??= Uri.tryParse(url)?.queryParameters['access_token'];
      if (token != null && token.isNotEmpty) {
        _didComplete = true;
        _finishSpotify(token);
        return true;
      }
      final err = Uri.tryParse(url)?.queryParameters['error'];
      if (err != null) {
        _didComplete = true;
        if (mounted) Navigator.of(context).pop(null);
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _onGoogleUrl(String url) {
    if (!url.contains('code=') && !url.contains('oauth2callback')) return false;
    try {
      final uri = Uri.tryParse(url);
      final code = uri?.queryParameters['code'];
      final err = uri?.queryParameters['error'];
      if (err != null) {
        _didComplete = true;
        if (mounted) Navigator.of(context).pop(null);
        return true;
      }
      if (code != null && code.isNotEmpty) {
        _didComplete = true;
        _finishGoogle(code);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _finishSpotify(String token) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('https://api.spotify.com/v1/me'),
          headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final images = d['images'] as List?;
        if (mounted) {
          Navigator.of(context).pop({
            'token': token,
            'name': d['display_name'] as String? ?? 'Spotify User',
            'email': d['email'] as String? ?? '',
            'avatar': images?.isNotEmpty == true ? images!.first['url'] as String? : null,
            'provider': 'spotify',
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) Navigator.of(context).pop({'token': token, 'provider': 'spotify'});
  }

  Future<void> _finishGoogle(String code) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://veltrixcode-ytify.hf.space/api/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          Navigator.of(context).pop({
            'token': d['token'] as String?,
            'name': (d['user'] as Map?)?['name'] ?? (d['user'] as Map?)?['username'] ?? 'Google User',
            'email': (d['user'] as Map?)?['email'] ?? '',
            'avatar': (d['user'] as Map?)?['avatar'],
            'provider': 'google',
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) Navigator.of(context).pop({'provider': 'google'});
  }

  @override
  Widget build(BuildContext context) {
    final isSpotify = widget.provider == AuthProvider.spotify;
    final accent = isSpotify ? const Color(0xFF1DB954) : const Color(0xFF4285F4);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF111111),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.of(context).pop(null)),
          title: Text(isSpotify ? 'Sign in to Spotify' : 'Sign in with Google',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          centerTitle: true,
          bottom: _isLoading
              ? PreferredSize(preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: accent))
              : null,
          systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
