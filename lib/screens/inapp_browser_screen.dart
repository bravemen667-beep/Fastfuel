// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — In-App Browser Screen
//  Opens URLs inside the app using WebView with a back arrow.
//  Used for gofaster.in and any external web links.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class InAppBrowserScreen extends StatefulWidget {
  final String url;
  final String title;

  const InAppBrowserScreen({
    super.key,
    required this.url,
    this.title = 'GoFaster',
  });

  /// Convenience navigator — handles web fallback gracefully
  static Future<void> open(BuildContext context, {String? url, String? title}) {
    final target = url ?? 'https://gofaster.in';
    final label  = title ?? 'GoFaster';
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppBrowserScreen(url: target, title: label),
        fullscreenDialog: false,
      ),
    );
  }

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController? _controller;
  bool _loading = true;
  int  _progress = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _loading = false);
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
      _controller = ctrl;
    } else {
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: kIsWeb ? _buildWebFallback() : _buildWebView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: AppColors.secondary,
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                // Back arrow
                GestureDetector(
                  onTap: () async {
                    if (_controller != null && await _controller!.canGoBack()) {
                      await _controller!.goBack();
                    } else {
                      // ignore: use_build_context_synchronously
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 48, height: 56,
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                ),
                // Title
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.h5,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Refresh
                GestureDetector(
                  onTap: () => _controller?.reload(),
                  child: Container(
                    width: 48, height: 56,
                    alignment: Alignment.center,
                    child: const Icon(Icons.refresh_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        // Progress bar
        if (_loading)
          Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
      ],
    );
  }

  Widget _buildWebFallback() {
    // Web platform: show iframe-like message with link
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.fire,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text('GoFaster Store', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'Visit us at gofaster.in for GoFaster vitamins, tablets, and supplements.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.url,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
