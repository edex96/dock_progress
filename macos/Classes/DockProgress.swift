
public enum DockProgress {
	private static var progressObserver: NSKeyValueObservation?
	private static var finishedObserver: NSKeyValueObservation?
	private static var elapsedTimeSinceLastRefresh = 0.0
	private static let defaultView = NSApp.dockTile.contentView

	// TODO: Use `CADisplayLink` on macOS 14.
	private static var displayLinkObserver = DisplayLinkObserver { displayLinkObserver, refreshPeriod in
		DispatchQueue.main.async {
			let speed = 1.0
			elapsedTimeSinceLastRefresh += speed * refreshPeriod
			if (displayedProgress - progress).magnitude <= 0.01 {
				displayedProgress = progress
				elapsedTimeSinceLastRefresh = 0
				displayLinkObserver.stop()
			} else {
				displayedProgress = Easing.linearInterpolation(
					start: displayedProgress,
					end: progress,
					progress: Easing.easeInOut(progress: elapsedTimeSinceLastRefresh)
				)
			}
			updateDockIcon()
		}
	}

	private static let dockContentView = with(ContentView()) {
		NSApp.dockTile.contentView = $0
	}

	public static var progress: Double = 0 {
		didSet {
			if progress > 0 {
				NSApp.dockTile.contentView = dockContentView
				displayLinkObserver.start()
			} else {
				updateDockIcon()
			}
		}
	}

	public private(set) static var displayedProgress = 0.0 {
		didSet {
			if displayedProgress == 0 || displayedProgress >= 1 {
				NSApp.dockTile.contentView = defaultView
			}
 		}
	}

	public static func resetProgress() {
		displayLinkObserver.stop()
		progress = 0
		displayedProgress = 0
		elapsedTimeSinceLastRefresh = 0
		updateDockIcon()
	}

	private static func updateDockIcon() {
		dockContentView.needsDisplay = true
		NSApp.dockTile.display()
	}

	private final class ContentView: NSView {
		override func draw(_ dirtyRect: CGRect) {
			NSGraphicsContext.current?.imageInterpolation = .high
			NSApp.applicationIconImage?.draw(in: bounds)
			guard
				displayedProgress > 0,
				displayedProgress < 1
			else {
				return
			}
			guard let cgContext = NSGraphicsContext.current?.cgContext else {
				return
			}
			let progressCircle = ProgressCircleShapeLayer(radius: 60, center: bounds.center)
			progressCircle.strokeColor = CGColor(red: 0.537, green: 0, blue: 0.302, alpha: 1)
			progressCircle.lineWidth = 8
			progressCircle.progress = displayedProgress
			progressCircle.render(in: cgContext)
		}
	}
}




