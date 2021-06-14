load('labelingSession.mat'); 
%%
% Add the images location to the MATLAB path.
imDir = 'D:\TA_noni\Data Training\Positif';
addpath(imDir);
%%
% Specify the folder for negative images.
negativeFolder = 'D:\TA_noni\Data Training\Negatif';  
%%
% Train a cascade object detector 
trainCascadeObjectDetector('platDetectorLBP.xml', positiveInstances,negativeFolder,'FalseAlarmRate',0.2,'NumCascadeStages',17, 'FeatureType', 'LBP');
%%