import CoreVideo
import simd

@discardableResult
func with<T>(_ item: T, update: (inout T) throws -> Void) rethrows -> T {
	var this = item
	try update(&this)
	return this/*  */
}

final class DisplayLinkObserver {
	private var displayLink: CVDisplayLink?
	fileprivate let callback: (DisplayLinkObserver, Double) -> Void

	init(_ callback: @escaping (DisplayLinkObserver, Double) -> Void) {
		self.callback = callback
		guard CVDisplayLinkCreateWithActiveCGDisplays(&displayLink) == kCVReturnSuccess else {
			assertionFailure("Failed to create CVDisplayLink")
			print("Failed to create CVDisplayLink")
			return
		}
	}

	deinit {
		stop()
	}

	func start() {
		guard let displayLink else {
			return
		}
		let result = CVDisplayLinkSetOutputCallback(
			displayLink,
			displayLinkOutputCallback,
			UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
		)
		assert(result == kCVReturnSuccess, "Failed to set CVDisplayLink output callback")
		CVDisplayLinkStart(displayLink)
	}

	func stop() {
		guard let displayLink else {
			return
		}
		CVDisplayLinkStop(displayLink)
	}
}


private func displayLinkOutputCallback(
	displayLink: CVDisplayLink,
	inNow: UnsafePointer<CVTimeStamp>,
	inOutputTime: UnsafePointer<CVTimeStamp>,
	flagsIn: CVOptionFlags,
	flagsOut: UnsafeMutablePointer<CVOptionFlags>,
	displayLinkContext: UnsafeMutableRawPointer?
) -> CVReturn {
	let observer = unsafeBitCast(displayLinkContext, to: DisplayLinkObserver.self)
	var refreshPeriod = CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink)
	if refreshPeriod == 0 {
		print("Warning: CVDisplayLinkGetActualOutputVideoRefreshPeriod failed. Assuming 60 Hz...")
		refreshPeriod = 1.0 / 60.0
	}
	observer.callback(observer, refreshPeriod)
	return kCVReturnSuccess
}


final class ProgressCircleShapeLayer: CAShapeLayer {
	convenience init(radius: Double, center: CGPoint) {
		self.init()
		fillColor = nil
		lineCap = .round
		position = center
		strokeEnd = 0
		let cgPath = NSBezierPath.progressCircle(radius: radius, center: center).ss_cgPath
		path = cgPath
		bounds = cgPath.boundingBox
	}

	var progress: Double {
		get { strokeEnd }
		set {
			// Multiplying by `1.02` ensures that the start and end points meet at the end. Needed because of the round line cap.
			strokeEnd = newValue * 1.02
		}
	}
}


enum Easing {
	static func linearInterpolation(start: Double, end: Double, progress: Double) -> Double {
		assert(0...1 ~= progress, "Progress must be between 0.0 and 1.0")
		return Double(simd_mix(Float(start), Float(end), Float(progress)))
	}
	static private func easeIn(progress: Double) -> Double {
		assert(0...1 ~= progress, "Progress must be between 0.0 and 1.0")
		return Double(simd_smoothstep(0.0, 1.0, Float(progress)))
	}
	static private func easeOut(progress: Double) -> Double {
		assert(0...1 ~= progress, "Progress must be between 0.0 and 1.0")
		return 1 - easeIn(progress: 1 - progress)
	}
	static func easeInOut(progress: Double) -> Double {
		assert(0...1 ~= progress, "Progress must be between 0.0 and 1.0")
		return linearInterpolation(
			start: easeIn(progress: progress),
			end: easeOut(progress: progress),
			progress: progress
		)
	}
}


extension NSBezierPath {
	func copyPath() -> Self {
		copy() as! Self
	}

	func rotationTransform(byRadians radians: Double, centerPoint point: CGPoint) -> AffineTransform {
		var transform = AffineTransform()
		transform.translate(x: point.x, y: point.y)
		transform.rotate(byRadians: radians)
		transform.translate(x: -point.x, y: -point.y)
		return transform
	}

	func rotating(byRadians radians: Double, centerPoint point: CGPoint) -> Self {
		let path = copyPath()

		guard radians != 0 else {
			return path
		}

		let transform = rotationTransform(byRadians: radians, centerPoint: point)
		path.transform(using: transform)
		return path
	}
}


extension NSBezierPath {
	/**
	UIKit polyfill.
	*/
	var ss_cgPath: CGPath {
		if #available(macOS 14, *) {
			return cgPath
		}

		let path = CGMutablePath()
		var points = [CGPoint](repeating: .zero, count: 3)

		for index in 0..<elementCount {
			let type = element(at: index, associatedPoints: &points)
			switch type {
			case .moveTo:
				path.move(to: points[0])
			case .lineTo:
				path.addLine(to: points[0])
			case .curveTo:
				path.addCurve(to: points[2], control1: points[0], control2: points[1])
			case .closePath:
				path.closeSubpath()
			default:
				continue
			}
		}

		return path
	}

	/**
	UIKit polyfill.
	*/
	convenience init(roundedRect rect: CGRect, cornerRadius: CGFloat) { // swiftlint:disable:this no_cgfloat
		self.init(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
	}

	/**
	UIKit polyfill.
	*/
	func addLine(to point: CGPoint) {
		line(to: point)
	}

	/**
	UIKit polyfill.
	*/
	func addCurve(to endPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
		curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
	}
}



extension NSBezierPath {
	static func progressCircle(radius: Double, center: CGPoint) -> Self {
		let startAngle = 90.0
		let path = self.init()
		path.appendArc(
			withCenter: center,
			radius: radius,
			startAngle: startAngle,
			endAngle: startAngle - 360,
			clockwise: true
		)
		return path
	}
}


extension CGRect {
	var center: CGPoint {
		get { CGPoint(x: midX, y: midY) }
		set {
			origin = CGPoint(
				x: newValue.x - (size.width / 2),
				y: newValue.y - (size.height / 2)
			)
		}
	}
}