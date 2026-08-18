import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EduPodWebViewApp(),
  ));
}

class EduPodWebViewApp extends StatefulWidget {
  const EduPodWebViewApp({super.key});

  @override
  State<EduPodWebViewApp> createState() => _EduPodWebViewAppState();
}

class _EduPodWebViewAppState extends State<EduPodWebViewApp> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("EduPodApp/1.0 (Flutter; Cross-Platform)")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          // 🛡️ [보안 강화] 악성 사이트 및 피싱 차단 (edupod.kr 페이지만 웹뷰 내 허용)
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.host.isEmpty || uri.host.endsWith('edupod.kr')) {
              return NavigationDecision.navigate;
            }
            // 외부 링크나 검증되지 않은 도메인은 앱 내부 실행 차단
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://edupod.kr'));
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Flutter 3.22 호환 뒤로가기 제어 (앱 종료 방지 및 이전 페이지 이동)
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: const Color(0xFF3B82F6),
                onRefresh: () async {
                  await _controller.reload();
                },
                child: WebViewWidget(controller: _controller),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
