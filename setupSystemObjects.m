function obj = setupSystemObjects()
obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 586, 'MinimumBackgroundRatio', 0.7);

  
  obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', 4000,'MaximumBlobArea', 2700000);
        
        
end