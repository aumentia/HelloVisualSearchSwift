//
//  ViewController.swift
//  HelloVisualSearchSwift
//
//  Created by Pablo GM on 04/09/15.
//  Copyright (c) 2015 Aumentia Technologies SL. All rights reserved.
//

import UIKit

class ViewController: UIViewController, imageMatchedProtocol, QRMatchedProtocol, CameraCaptureDelegate
{
    var _myVs:vsPlugin!;
    var _captureManager:CaptureSessionManager!;
    var _cameraView:UIView!;
    var _myLoading:UIAlertView!;
    var _resPic:UIImageView!;
    
    
    // MARK: - View Life Cycle
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated);
        
        let myLogo:UIImage          = UIImage(named: "aumentia®.png")!;
        let myLogoView:UIImageView  = UIImageView(image: myLogo);
        myLogoView.frame            = CGRect(x: 0, y: 0, width: 150, height: 61);
        self.view.addSubview(myLogoView);
        self.view.bringSubview(toFront: myLogoView);
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
        
        initCapture();
        
        addVisualSearch();
        
        addLoading();
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            self.addImages();
        }
        
        ///// TESTS /////
        
        //addCropRect();
        
        //addQRRois();
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewDidAppear(animated);
        
        removeCapture();
        
        removeImages();
        
        removeVisualSearch();
    }

    
    // MARK: - Memory Management
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Add / Remove images
    
    func addImages()
    {
        autoreleasepool
        {
            /// Local
            for i in 1...6
            {
                let imageName:NSString = NSString(format: "pic%d.jpg", i);
                let res:Bool           = _myVs.insert(UIImage(named: imageName as String), withId: i);
                
                print("Image \(imageName) %@", res ? "ADDED" : "NOT ADDED");
            }
            
            /// Remote
            let resId:NSInteger = _myVs.insertImage(from: URL(string: "https://s3-us-west-1.amazonaws.com/aumentia/pic_from_url.jpg"));
            
            if ( resId == -1 )
            {
                print("Error adding image from URL");
            }
            else
            {
                print("Image from URL added with id \(resId)");
            }
            
            DispatchQueue.main.async
            {
                self.removeLoading();
            }
        }
    }
    
    func removeImages()
    {
        _myVs.deleteAllImages();
    }
    
    
    // MARK: - Loading
    
    func addLoading()
    {
        _myLoading = UIAlertView(title: "Loading...", message: nil, delegate: nil, cancelButtonTitle: nil);
        let spinner:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge);
        spinner.center = CGPoint(x: 142, y: 70);
        spinner.startAnimating();
        _myLoading.addSubview(spinner);
        _myLoading.show();
    }
    
    func removeLoading()
    {
        _myLoading.dismiss(withClickedButtonIndex: 0, animated: true);
        _myLoading = nil;
    }
    
    
    // MARK: - VS Life Cycle
    
    func addVisualSearch()
    {
        if _myVs == nil
        {
            // Init
            _myVs = vsPlugin(key: "d680e7fd66b2d076a2406e9a78629db1144d3460", setDebug: false);
            
            assert(_myVs != nil, "Review your API KEY.");
            
            // Set delegates
            _myVs.imageDelegate = self;
            _myVs.qrDelegate    = self;
            
            // Set detection threshold
            _myVs.setMatchingThreshold(8);
            
            // Set mode
            _myVs.setSearch(search_mode.all);
            
            // Set mode: search for QR and / or bar codes and images
            _myVs.initMotionDetection(withThreshold: 3, enableDebugLog: false);
            
            // Some more settings
//            _myVs.filterWindow = 5;
//            _myVs.maxFeatures  = 50;
//            _myVs.frameSize    = 250;
        }
    }
    
    func removeVisualSearch()
    {
        if _myVs != nil
        {
            _myVs.removeMotionDetection();
            
            _myVs.imageDelegate = nil;
            _myVs.qrDelegate    = nil;
            _myVs               = nil;
        }
    }
    
    
    // MARK: - ROIs and Crop Rects
    
    func addRectToView(_ rect:CGRect)
    {
        let frameView:UIView        = UIView(frame: rect);
        frameView.backgroundColor   = UIColor.clear;
        frameView.layer.borderColor = UIColor(red: 0.0/255.0, green: 158.0/255.0, blue: 224.0/255.0, alpha: 1.0).cgColor;
        frameView.layer.borderWidth = 3.0;
        self.view.addSubview(frameView);
    }
    
    func addQRRois()
    {
        // Add regions to match several QR / bar codes
        let ROI1:Roi = Roi(rect: CGRect(x: 0, y: 0, width: 160, height: 240));
        let ROI2:Roi = Roi(rect: CGRect(x: 0, y: 240, width: 160, height: 240));
        let ROI3:Roi = Roi(rect: CGRect(x: 160, y: 0, width: 160, height: 240));
        let ROI4:Roi = Roi(rect: CGRect(x: 160, y: 240, width: 160, height: 240));
        
        // Draw the regions
        addRectToView(CGRect(x: 0, y: 0, width: 160, height: 240));
        addRectToView(CGRect(x: 0, y: 240, width: 160, height: 240));
        addRectToView(CGRect(x: 160, y: 0, width: 160, height: 240));
        addRectToView(CGRect(x: 160, y: 240, width: 160, height: 240));
        
        // Add them to the system
        _myVs.addQRRect(ROI1);
        _myVs.addQRRect(ROI2);
        _myVs.addQRRect(ROI3);
        _myVs.addQRRect(ROI4);
    }
    
    func addCropRect()
    {
        let myRect:CGRect = CGRect(x: 20, y: 20, width: 200, height: 125);
        
        addRectToView(myRect);
        
        _myVs.imageCropRect = myRect;
    }
    

    // MARK: - Camera management
    
    func initCapture()
    {
        // Init capture manager
        _captureManager = CaptureSessionManager();
        
        // Set delegate
        _captureManager.delegate = self;
        
        // Set video streaming quality
        _captureManager.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        
        _captureManager.outPutSetting = NSNumber(value: kCVPixelFormatType_32BGRA as UInt32);
        
        _captureManager.addVideoInput(AVCaptureDevicePosition.back);
        _captureManager.addVideoOutput();
        _captureManager.addVideoPreviewLayer();
        
        let layerRect:CGRect = self.view.bounds;
        
        _captureManager.previewLayer.isOpaque = false;
        _captureManager.previewLayer.bounds = layerRect;
        _captureManager.previewLayer.position = CGPoint(x: layerRect.midX, y: layerRect.midY);
        
        // Create a view where we attach the AV Preview Layer
        _cameraView = UIView(frame: self.view.bounds);
        _cameraView.layer .addSublayer(_captureManager.previewLayer);
        
        // Add the view we just created as a subview to the View Controller's view
        self.view.addSubview(_cameraView);
        
        // Start
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            
            self.startCaptureManager();
        }
    }
    
    func removeCapture()
    {
        _captureManager.captureSession.stopRunning();
        _cameraView.removeFromSuperview();
        _captureManager = nil;
        _cameraView     = nil;
    }
    
    func startCaptureManager()
    {
        autoreleasepool
        {
            _captureManager.captureSession.startRunning();
        }
    }
    
    
    // MARK: - Camera management
    
    func processNewCameraFrameRGB(_ cameraFrame: CVImageBuffer!)
    {
        _myVs.processRGBFrame(cameraFrame, saveImageToPhotoAlbum: false);
    }
    
    func processNewCameraFrameYUV(_ cameraFrame: CVImageBuffer!)
    {
        _myVs.processYUVFrame(cameraFrame, saveImageToPhotoAlbum: false);
    }
    
    
    // MARK: - Visual Search Delegates
    
    func imageMatchedResult(_ uId: Int)
    {
        if uId != -1
        {
            print("Image detected --> \(uId)");
            
            DispatchQueue.main.async
            {
                let imageName = NSString(format: "pic%ld.jpg", uId) as String;
                let image     = UIImage(named: imageName);
                
                assert(image != nil, "Image \(imageName) does not exist");
                
                if self._resPic == nil
                {
                    self._resPic        = UIImageView(image: image);
                    self._resPic.frame  = CGRect(x: 0, y: self.view.frame.height - 70, width: 100, height: 63);
                    self.view.addSubview(self._resPic);
                }
                else
                {
                    self._resPic.image = image;
                }
                
                self._resPic.isHidden = false;
            }
        }
        else
        {
            DispatchQueue.main.async
            {
                if self._resPic != nil
                {
                    self._resPic.isHidden = true;
                }
            }
        }
    }
    
    func singleQRMatchedResult(_ res: String!)
    {
        if res != ""
        {
            let message = "QR / bar code detected --> \(res)";
            
            showAlert(message);
        }
    }
    
    func multipleQRMatchedResult(_ codes: [Any]!) {
        
        var code = "";
        
        for i in 0...codes.count - 1
        {
            let roi:Roi = codes[i] as! Roi;
            
            code = code + roi.qrString + "\n";
        }
        
        showAlert(code);
    }
    
    func showAlert(_ message: String)
    {
        let alert = UIAlertController(title: "HelloVisualSearch Swift", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

