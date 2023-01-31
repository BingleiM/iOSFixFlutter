##集成
###采用方案三 - 使用 CocoaPods 在 Xcode 和 Flutter 框架中内嵌应用和插件框架

#####除了将一个很大的 Flutter.framework 分发给其他开发者、机器或者持续集成 (CI) 系统之外，你可以加入一个参数 --cocoapods 将 Flutter 框架作为一个 CocoaPods 的 podspec 文件分发。这将会生成一个 Flutter.podspec 文件而不再生成 Flutter.framework 引擎文件。如选项 B 中所说的那样，它将会生成 App.framework 和插件框架。

> 要生成 Flutter.podspec 和框架，命令行切换到 Flutter module 根目录，然后运行以下命令：

`flutter build ios-framework --cocoapods --output=some/path/MyApp/Flutter/`

> 输出文件目录结构为：

```
some/path/MyApp/

└── Flutter/

├── Debug/

│ ├── Flutter.podspec

│   ├── App.xcframework

│   ├── FlutterPluginRegistrant.xcframework

│   └── example_plugin.xcframework (each plugin with iOS platform code is a separate framework)

├── Profile/

│ ├── Flutter.podspec

│ ├── App.xcframework

│ ├── FlutterPluginRegistrant.xcframework

│ └── example_plugin.xcframework

└── Release/

├── Flutter.podspec

├── App.xcframework

├── FlutterPluginRegistrant.xcframework

└── example_plugin.xcframework
```
#### 1\. 在 iOS 原生工程中使用 CocoaPods, 添加 Flutter 到 Podfile 文件中

pod 'Flutter', :podspec => 'some/path/MyApp/Flutter/[build mode]/Flutter.podspec'

⚠️ build mode 为要使用的编译环境, 对应上面目录 Debug、Profile、Release

例如: pod 'Flutter', :podspec => '../FlutterModules/Flutter/Debug/Flutter.podspec'

#### 2\. 将对应编译环境中的 App.xcframework、FlutterPluginRegistrant.xcframework 引用到工程中, 并设置 Embed & Sign

![image](https://upload-images.jianshu.io/upload_images/1891529-dd33205ac8c97fd9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 3\. 运行 pod install
#### 4\. 加载 Flutter 页面

```swift
import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

    lazy var flutterEngine = FlutterEngine(name: "My Flutter Engine")

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        flutterEngine.run()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions);
    }
}
```

```swift
import UIKit
import Flutter

class ViewController: UIViewController {

    @IBAction func pushAction(_ sender: UIButton) {
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
        let flutterVC = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        self.navigationController?.pushViewController(flutterVC, animated: true)
    }
}
```
![Simulator Screen Shot - iPhone 14 Pro - 2023-01-31 at 14.26.49.png](https://upload-images.jianshu.io/upload_images/1891529-4f9901ee3a7e88cc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


参考文档: [https://flutter.cn/docs/development/add-to-app/ios/project-setup](https://flutter.cn/docs/development/add-to-app/ios/project-setup)

##iOS 和 Flutter 交互
#### FlutterMethodChannel 为 iOS 和 Flutter 交互的通道
### Flutter 方:
```Dart
class _MyHomePageState extends State<MyHomePage> {
  // Get battery level.
  static const platform = MethodChannel('samples.flutter.dev/battery');

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }


  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
   return Material(
     child: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
         children: [
           ElevatedButton(
             onPressed: _getBatteryLevel,
             child: const Text('Get Battery Level'),
           ),
           Text(_batteryLevel),
         ],
       ),
     ),
   );
 }
}
```
### iOS 方:
> 示例: Flutter 调用 iOS 原生方法, 获取电池电量

⚠️ 其中 getBatteryLevel 为 Flutter 中调用 invokeMethod 中指定的方法名

```Swift
@IBAction func pushAction(_ sender: UIButton) {
    let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
    let flutterVC = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    // FlutterMethodChannel 为平台通道
    let channel = FlutterMethodChannel(name: "samples.flutter.dev/battery", binaryMessenger: flutterVC.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
        // Flutter 调用原生回调
        debugPrint("handle flutter messages", call.method)
        if call.method == "getBatteryLevel" {
            self?.receiveBatteryLevel(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    self.present(flutterVC, animated: true)
}

// MARK: -- Flutter 调用 原生 --
private func receiveBatteryLevel(result: FlutterResult) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    if device.batteryState == UIDevice.BatteryState.unknown {
        result(FlutterError(code: "UNAVAILABLE",
                            message: "Battery level not available.",
                            details: nil))
    } else {
        // 这里 iOS 向 Flutter 传参
        result(Int(device.batteryLevel * 100))
    }
}
```
