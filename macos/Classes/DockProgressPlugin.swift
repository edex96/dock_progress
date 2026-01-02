import FlutterMacOS


public class DockProgressPlugin: NSObject, FlutterPlugin {
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dock_progress", binaryMessenger: registrar.messenger)
    let instance = DockProgressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "start":
        startTimer()
        result(nil)

      case "stop":
        self.timer?.invalidate()
        self.timer = nil
        DockProgress.progress = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DockProgress.resetProgress()
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
    }
  }

  var timer : Timer?
  private func startTimer(){
    guard timer == nil else { return }
    timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
				if DockProgress.displayedProgress >= 1 {
						DockProgress.resetProgress()
            self.timer?.invalidate()
            self.timer = nil
            self.startTimer()
				}else{
          DockProgress.progress += 0.1
        }
		}
  }
}
