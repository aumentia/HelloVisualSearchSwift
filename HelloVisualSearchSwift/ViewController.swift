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
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated);
        
        let myLogo:UIImage          = UIImage(named: "aumentia®.png")!;
        let myLogoView:UIImageView  = UIImageView(image: myLogo);
        myLogoView.frame            = CGRectMake(0, 0, 150, 61);
        self.view.addSubview(myLogoView);
        self.view.bringSubviewToFront(myLogoView);
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated);
        
        initCapture();
        
        addVisualSearch();
        
        addLoading();
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
        {
            self.addImages();
        }
        
        ///// TESTS /////
        
        //addCropRect();
        
        //addQRRois();
    }
    
    override func viewWillDisappear(animated: Bool)
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
            for var i = 1; i <= 6; ++i
            {
                let imageName:NSString = NSString(format: "pic%d.jpg", i);
                let res:Bool           = _myVs.insertImage(UIImage(named: imageName as String), withId: i);
                
                println("Image \(imageName) %@", res ? "ADDED" : "NOT ADDED");
            }
            
            /// Remote
            let resId:NSInteger = _myVs.insertImageFromURL(NSURL(string: "https://s3-us-west-1.amazonaws.com/aumentia/pic_from_url.jpg"));
            
            if ( resId == -1 )
            {
                println("Error adding image from URL");
            }
            else
            {
                println("Image from URL added with id \(resId)");
            }
            
            dispatch_async(dispatch_get_main_queue())
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
        let spinner:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge);
        spinner.center = CGPointMake(142, 70);
        spinner.startAnimating();
        _myLoading.addSubview(spinner);
        _myLoading.show();
    }
    
    func removeLoading()
    {
        _myLoading.dismissWithClickedButtonIndex(0, animated: true);
        _myLoading = nil;
    }
    
    
    // MARK: - VS Life Cycle
    
    func addVisualSearch()
    {
        if _myVs == nil
        {
            // Init
            _myVs = vsPlugin(key: "d680e7fd66b2d076a2406e9a78629db1144d3460", setDebug: true);
            
            assert(_myVs != nil, "Review your API KEY.");
            
            // Set delegates
            _myVs.imageDelegate = self;
            _myVs.qrDelegate    = self;
            
            // Set detection threshold
            _myVs.setMatchingThreshold(8);
            
            // Set mode
            _myVs.setSearchMode(search_mode.all);
            
            // Set mode: search for QR and / or bar codes and images
            _myVs.initMotionDetectionWithThreshold(3, enableDebugLog: false);
            
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
    
    func addRectToView(rect:CGRect)
    {
        let frameView:UIView        = UIView(frame: rect);
        frameView.backgroundColor   = UIColor.clearColor();
        frameView.layer.borderColor = UIColor(red: 0.0/255.0, green: 158.0/255.0, blue: 224.0/255.0, alpha: 1.0).CGColor;
        frameView.layer.borderWidth = 3.0;
        self.view.addSubview(frameView);
    }
    
    func addQRRois()
    {
        // Add regions to match several QR / bar codes
        let ROI1:Roi = Roi(rect: CGRectMake(0, 0, 160, 240));
        let ROI2:Roi = Roi(rect: CGRectMake(0, 240, 160, 240));
        let ROI3:Roi = Roi(rect: CGRectMake(160, 0, 160, 240));
        let ROI4:Roi = Roi(rect: CGRectMake(160, 240, 160, 240));
        
        // Draw the regions
        addRectToView(CGRectMake(0, 0, 160, 240));
        addRectToView(CGRectMake(0, 240, 160, 240));
        addRectToView(CGRectMake(160, 0, 160, 240));
        addRectToView(CGRectMake(160, 240, 160, 240));
        
        // Add them to the system
        _myVs.addQRRect(ROI1);
        _myVs.addQRRect(ROI2);
        _myVs.addQRRect(ROI3);
        _myVs.addQRRect(ROI4);
    }
    
    func addCropRect()
    {
        let myRect:CGRect = CGRectMake(20, 20, 200, 125);
        
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
        
        _captureManager.outPutSetting = NSNumber(integer: kCVPixelFormatType_32BGRA);
        
        _captureManager.addVideoInput(AVCaptureDevicePosition.Back);
        _captureManager.addVideoOutput();
        _captureManager.addVideoPreviewLayer();
        
        let layerRect:CGRect = self.view.bounds;
        
        _captureManager.previewLayer.opaque = false;
        _captureManager.previewLayer.bounds = layerRect;
        _captureManager.previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
        
        // Create a view where we attach the AV Preview Layer
        _cameraView = UIView(frame: self.view.bounds);
        _cameraView.layer .addSublayer(_captureManager.previewLayer);
        
        // Add the view we just created as a subview to the View Controller's view
        self.view.addSubview(_cameraView);
        
        // Start
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
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
    
    func processNewCameraFrameRGB(cameraFrame: CVImageBuffer!)
    {
        _myVs.processRGBFrame(cameraFrame, saveImageToPhotoAlbum: false);
    }
    
    func processNewCameraFrameYUV(cameraFrame: CVImageBuffer!)
    {
        _myVs.processYUVFrame(cameraFrame, saveImageToPhotoAlbum: false);
    }
    
    
    // MARK: - Visual Search Delegates
    
    func imageMatchedResult(uId: Int)
    {
        if uId != -1
        {
            println("Image detected --> \(uId)");
            
            dispatch_async(dispatch_get_main_queue())
            {
                let imageName = NSString(format: "pic%ld.jpg", uId) as String;
                let image     = UIImage(named: imageName);
                
                assert(image != nil, "Image \(imageName) does not exist");
                
                if self._resPic == nil
                {
                    self._resPic        = UIImageView(image: image);
                    self._resPic.frame  = CGRectMake(0, self.view.frame.height - 70, 100, 63);
                    self.view.addSubview(self._resPic);
                }
                else
                {
                    self._resPic.image = image;
                }
                
                self._resPic.hidden = false;
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue())
            {
                if self._resPic != nil
                {
                    self._resPic.hidden = true;
                }
            }
        }
    }
    
    func singleQRMatchedResult(res: String!)
    {
        if res != ""
        {
            let message = "QR / bar code detected --> \(res)";
            
            showAlert(message);
        }
    }
    
    func multipleQRMatchedResult(codes: [AnyObject]!)
    {
        var code = "";
        
        for var i = 0; i <= codes.count - 1; ++i
        {
            let roi:Roi = codes[i] as! Roi;
            
            code = code + roi.qrString + "\n";
        }
        
        showAlert(code);
    }
    
    func showAlert(message: String)
    {
        var alert = UIAlertController(title: "HelloVisualSearch Swift", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

