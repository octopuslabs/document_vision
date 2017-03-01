import UIKit
import AVFoundation
import SwiftyJSON
import CoreGraphics

class CaptureController: UIViewController {

    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var startCaptureButton: UIBarButtonItem!
    @IBOutlet weak var takePhotoButton: UIBarButtonItem!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var edgesView: UIImageView!
    
    var timer:Timer?

    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPresetPhoto
        setupCamera();
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.previewLayer?.frame = self.previewView.frame
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let t = timer {
            t.invalidate()
        }
        
    }
    
    func setupCamera() {
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // testing error
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        }
        catch let error1 as NSError{
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        // session setup
        if error == nil && (captureSession?.canAddInput(input))!{
            captureSession?.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        }
        
        // configure live preview
        if (captureSession?.canAddOutput(stillImageOutput))!{
            captureSession?.addOutput(stillImageOutput)
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            previewLayer?.captureDevicePointOfInterest(for: CGPoint.init(x: 0.5, y: 0.5))
            previewView.layer.addSublayer(previewLayer!)
            captureSession?.startRunning()
        }
    }
    
    
    @IBAction func autoCaptureStarted(_ sender: UIBarButtonItem) {

        timer = Timer.scheduledTimer(timeInterval: 1.0, target:self, selector: #selector(CaptureController.takePhoto(_:)), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo){
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {[weak self]
                buffer, error in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let dataProvider = CGDataProvider(data: imageData as! CFData)
                let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                var imageOrientation : UIImageOrientation?
                
                switch UIDevice.current.orientation {
                case UIDeviceOrientation.portraitUpsideDown:
                    imageOrientation = UIImageOrientation.left
                case UIDeviceOrientation.landscapeRight:
                    imageOrientation = UIImageOrientation.down
                case UIDeviceOrientation.landscapeLeft:
                    imageOrientation = UIImageOrientation.up
                case UIDeviceOrientation.portrait:
                    imageOrientation = UIImageOrientation.right
                default:
                    imageOrientation = UIImageOrientation.right
                }
                
                let img = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: imageOrientation!)
                self?.applyCannyFilter(img: img)
                
//                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)

            })
        }
    }
    
    private func applyCannyFilter(img:UIImage) {
        
        
        //            self.spinner.startAnimating()
        
        DispatchQueue.global().async {
            let cannedImage:UIImage = CVWrapper.processCanny(with: img) as UIImage
            
            DispatchQueue.main.async {
                let ar = CVWrapper.maxBoundingPoly(with: img)
                self.edgesView.image = self.drawPointsOnImage(image: cannedImage, points: (ar as? Array<CGPoint>)!)
                //                self.spinner.stopAnimating()
            }
        }
    }
    
    func drawPointsOnImage(image: UIImage, points: Array<CGPoint>) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = image.scale
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Pass 1: Draw the original image as the background
//        image.draw(at: CGPoint(x: 0, y: 0))
        
        // Pass 2: Draw the line on top of original image
        context!.setLineWidth(10.0)
        context!.setStrokeColor(UIColor.red.cgColor);
        context?.move(to: points[0])
        
        for p in points {
            context?.addLine(to: p)
        }
        context?.addLine(to: points[0])
        context!.strokePath();
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}

