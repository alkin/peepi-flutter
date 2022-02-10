import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:url_launcher/url_launcher.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentTabIndex = 0;

  final GlobalKey webViewKeyA = GlobalKey();
  final GlobalKey webViewKeyB = GlobalKey();
  final GlobalKey webViewKeyC = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewController? popupController;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        supportMultipleWindows: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      InAppWebView(
        key: webViewKeyA,
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://peepi-test-flutter.vercel.app/")),
        initialOptions: options,
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onCreateWindow: openPopup,
        onConsoleMessage: (controller, message) {
          print("console: ${message}");
        },
      ),
      InAppWebView(
        key: webViewKeyB,
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://peepi-test-flutter.vercel.app/file")),
        initialOptions: options,
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onCreateWindow: openPopup,
      ),
      InAppWebView(
        key: webViewKeyC,
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://peepi-test-flutter.vercel.app/video")),
        initialOptions: options,
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onCreateWindow: openPopup,
      ),
      InAppWebView(
        key: webViewKeyC,
        initialUrlRequest: URLRequest(
            url: Uri.parse("https://peepi-test-flutter.vercel.app/whatsapp")),
        initialOptions: options,
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onCreateWindow: openPopup,
      ),
    ];

    final navbarItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Popup'),
      const BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'File'),
      const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Video'),
      const BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'WhatsApp'),
    ];

    assert(tabs.length == navbarItems.length);

    final bottomNavBar = BottomNavigationBar(
      items: navbarItems,
      currentIndex: currentTabIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          currentTabIndex = index;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Teste Peepi"),
      ),
      body: tabs[currentTabIndex],
      bottomNavigationBar: bottomNavBar,
    );
  }

  Future<bool?> openPopup(controller, createWindowRequest) async {
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
            appBar: AppBar(),
            body: InAppWebView(
              // Setting the windowId property is important here!
              windowId: createWindowRequest.windowId,
              initialOptions: options,
              onWebViewCreated: (InAppWebViewController controller) async {
                popupController = controller;
              },
              // This function handles intent urls using url_launcher
              onLoadStart: (InAppWebViewController controller, Uri? url) async {
                // If it is an intent url
                if (!url.toString().startsWith(RegExp(r'^(https?|about)'))) {
                  try {
                    // Launch using url launcher
                    launch(url.toString());
                  } catch (_) {}

                  // and close the dialog
                  Navigator.of(context).pop();
                }
              },
              onLoadStop: (InAppWebViewController controller, Uri? url) async {
                // Setup window.opener.postMessage()
                controller.evaluateJavascript(
                    source:
                        "window.opener = { postMessage: function(data) { window.flutter_inappwebview.callHandler('message', data); }};");

                // Redirects messages to original webview
                controller.addJavaScriptHandler(
                    handlerName: 'message',
                    callback: (args) async {
                      String message = json.encode(args[0]);
                      print("popup message: ${message}");

                      // Since WebMessage accepts only strings as data
                      // we fake a postMessage using JSON.parse
                      webViewController?.evaluateJavascript(
                          source:
                              "window.postMessage(JSON.parse('${message}'));");

                      // Send closeWindow to hellojs
                      await controller.postWebMessage(
                          message: WebMessage(data: 'closeWindow'),
                          targetOrigin: Uri.parse("*"));
                    });
              },
              onCloseWindow: (InAppWebViewController controller) {
                Navigator.of(context).pop();
              },
            ));
      },
    );

    return true;
  }
}
