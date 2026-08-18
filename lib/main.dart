import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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

  // 💡 [중요] OneSignal 대시보드에서 발급받은 App ID를 여기에 입력하세요.
  // (임시 테스트 중이어도 빌드는 정상 통과됩니다)
  final String oneSignalAppId = "YOUR_ONESIGNAL_APP_ID";

  @override
  void initState() {
    super.initState();
    initPushNotifications();

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
          // 🛡️ 보안 필터: edupod.kr 내부 페이지만 허용
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.host.isEmpty || uri.host.endsWith('edupod.kr')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://edupod.kr'));
  }

  // 🔔 OneSignal 푸시 알림 초기화 및 클릭 핸들러
  Future<void> initPushNotifications() async {
    // 1. OneSignal 초기화
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);

    // 2. 알림 수신 권한 요청 팝업 (Android 13+ 및 iOS)
    OneSignal.Notifications.requestPermission(true);

    // 3. 푸시 알림 클릭 이벤트 처리 (알림 누르면 해당 글로 바로 이동)
    OneSignal.Notifications.addClickListener((event) {
      final customData = event.notification.additionalData;
      
      // 워드프레스 플러그인이 보낸 특정 글의 URL 추출
      if (customData != null && customData.containsKey('url')) {
        final targetUrl = customData['url'] as String;
        _controller.loadRequest(Uri.parse(targetUrl));
      } else if (event.notification.launchUrl != null) {
        _controller.loadRequest(Uri.parse(event.notification.launchUrl!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
