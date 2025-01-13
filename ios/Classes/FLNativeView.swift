import AVFoundation
import Flutter
import UIKit

public class FLNativeView: NSObject, FlutterPlatformView, VideoCaptureDelegate {
  private let previewView: UIView
  private let videoCapture: VideoCapture
  private var busy = false
  private var currentPosition: AVCaptureDevice.Position = .back
  private weak var methodHandler: MethodCallHandler?

  public init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    videoCapture: VideoCapture,
    methodHandler: MethodCallHandler
  ) {
    let screenSize: CGRect = UIScreen.main.bounds
    previewView = UIView(
      frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))

    self.videoCapture = videoCapture
    self.methodHandler = methodHandler

    super.init()

    videoCapture.nativeView = self
    videoCapture.delegate = methodHandler
    startCameraPreview(position: .back)
  }

  public func view() -> UIView {
    return previewView
  }

  private func startCameraPreview(position: AVCaptureDevice.Position) {
    print("DEBUG: Starting camera preview with position:", position)
    videoCapture.setUp(sessionPreset: .high, position: position) { success in
      if success {
        print("DEBUG: Video capture setup completed successfully")
        if let previewLayer = self.videoCapture.previewLayer {
          DispatchQueue.main.async {
            previewLayer.frame = self.previewView.bounds
            self.previewView.layer.addSublayer(previewLayer)
            print("DEBUG: Added preview layer to view")
          }
        }
        self.videoCapture.start()
        print("DEBUG: Started video capture")
        self.currentPosition = position
      } else {
        print("DEBUG: Failed to set up video capture")
      }
    }
  }

  func switchCamera() {
    print("DEBUG: switchCamera called in FLNativeView")
    if !busy {
      busy = true
      let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
      print("DEBUG: Switching from \(currentPosition) to \(newPosition)")
      
      DispatchQueue.main.async {
        self.videoCapture.previewLayer?.removeFromSuperlayer()
        self.videoCapture.stop()
        self.startCameraPreview(position: newPosition)
        self.busy = false
      }
    } else {
      print("DEBUG: Camera switch ignored - busy")
    }
  }

  // MARK: - VideoCaptureDelegate
  public func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
    // Forward frames to the method handler
    methodHandler?.videoCapture(capture, didCaptureVideoFrame: sampleBuffer)
  }
}
