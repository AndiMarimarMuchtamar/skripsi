         function varargout = TAPelat(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TAPelat_OpeningFcn, ...
                   'gui_OutputFcn',  @TAPelat_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function TAPelat_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.cdir = pwd;
set(handles.namafile,'enable','off');

% untuk menampilkan gambar pada background sistem
hback = axes('units','normalized','position',[0 0 1 1]);
uistack(hback,'bottom'); % menciptakan axes untuk tempat menampilkan gambar
[back map]=imread('image2.jpg');
image(back)
colormap(map)
background=imread('image1.jpg');
set(hback,'handlevisibility','off','visible','off')
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = TAPelat_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function alamat_Callback(hObject, eventdata, handles)

% pada bagian alamat folder yang dituju untuk data penelitian
function alamat_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%program untuk memilih folder yang akan di tuju pada sistem.
function pushbutton1_Callback(hObject, eventdata, handles)
handles.output = hObject;
fn = uigetdir(handles.cdir,'Pilih Folder');   
if fn ~= 0   
    handles.cdir = fn;    
    citra = dir(fullfile(handles.cdir,'*.mp4'));
    for x = 1 : length(citra)
        handles.namafiles{x} = VideoReader(fullfile(handles.cdir,citra(x).name));
    end   
    if length(citra) ~= 0
        set(handles.namafile,'enable','on');
    else
        set(handles.namafile,'enable','off');
    end
    set(handles.alamat,'string',handles.cdir);
    set(handles.namafile,'string',{},'value',1);
    set(handles.namafile,'string',{citra.name});    
end
guidata(hObject, handles);


% --- Executes on selection change in namafile.
function namafile_Callback(hObject, eventdata, handles)

% menampilkan list data penelitian yang sudah dipilih
function namafile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% program untuk tombol play
function play_Callback(hObject, eventdata, handles)
index = get(handles.namafile,'value');
obj=handles.namafiles{index};

% multiObjectTracking()
obj1 = setupSystemObjects();

bbox=zeros([20 4]);
sizebbox=size(bbox);
for dataframe=1:obj.NumberOfFrames
    c=zeros(sizebbox);
    frame=read(obj,dataframe);
      
    %Kalman Filter
    tracks = initializeTracks(); % buat array kosong dr track
    nextId = 1; % ID dari track selanjutnya
    
    
    %predikisi lokasi baru dr track
    for i = 1:length(tracks)
            box = tracks(i).box;
            
            % Memprediksi lokasi saat ini pada track
            predictedCentroid = predict(tracks(i).kalmanFilter);
            
            % Pergeseran bbox yg melompat-lompat sehingga pusat di lokasi yang diperkirakan.
            predictedCentroid = int32(predictedCentroid) - box(3:4) / 2;
            tracks(i).box = [predictedCentroid, box(3:4)];
    end

     %program akan jalan jika mendeteksi kendaraan  dengan yb>0
       mask = obj1.detector.step(frame);
       
        %mask = imopen(mask, strel('rectangle', [2,2]));
        %mask = imclose(mask, strel('rectangle', [15, 15]));
        mask = imfill(mask, 'holes');
        
        % Melakukan analisis untuk menemukan komponen yang terhubung
        [~, centroids, bboxes] = obj1.blobAnalyser.step(mask);
        
%menetapkan deteksi pada track
 nTracks = length(tracks);
        nDetections = size(centroids, 1);
        
        % menghitung banyaknya yang ditugaskan setiap deteksi pd setiap track.
        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end
        
        % memecahkan masalah penugasan.
        costOfNonAssignment = 20;
        [assignments, unassignedTracks, unassignedDetections] = ...
            assignDetectionsToTracks(cost, costOfNonAssignment);
       
        %perbarui track yang ditetapkan
 numAssignedTracks = size(assignments, 1);
 for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            box = bboxes(detectionIdx, :);
            
            % perbaiki perkiraan lokasi objek menggunakan deteksi baru
            correct(tracks(trackIdx).kalmanFilter, centroid);
            
            % mengganti prediksi bbox dengan deteksi bbox
            tracks(trackIdx).box = box;
            
            % Memperbarui track's age.
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            
            % Memperbarui visibilitas.
            tracks(trackIdx).totalVisibleCount = ...
                tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
 end
 
    %perbarui track yang blm ditetapkan
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end

% membuat track baru
centroids = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);
        
        for i = 1:size(centroids, 1)
            
            centroid = centroids(i,:);
            box = bboxes(i, :);
            
            % membuat sebuah objek Kalman filter.
            kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                centroid, [200, 50], [100, 25], 100);
            
            % membuat track baru.
            newTrack = struct(...
                'id', nextId, ... %ID integer dari lintasan
                'bbox', box, ... %kotak pembatas saat ini dari objek
                'kalmanFilter', kalmanFilter, ... %objek filter Kalman yang digunakan untuk gerakan berbasis pelacakan
                'age', 1, ... %jumlah frame sejak trek pertama kali terdeteksi
                'totalVisibleCount', 1, ... %jumlah total frame di mana trekterdeteksi (terlihat)
                'consecutiveInvisibleCount', 0); %jumlah frame berturut-turut untuk yang lintasannya tidak terdeteksi (tidak terlihat)
            
            % menambahkan array pada track.
            tracks(end + 1) = newTrack;
            
            % menambah ID selanjutnya.
            nextId = nextId + 1;
        end
        
% menampilkan hasil
 frame = im2uint8(frame);
        minVisibleCount = 8;
        if ~isempty(tracks)
              
            % Noisy detections tend to result in short-lived tracks.
            % Only display tracks that have been visible for more than 
            % a minimum number of frames.
            reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
            
            % menampilkan objek. jika sebuah onjek tdk terdeteksi pd frame.tampilkan prediksi bbox 
            if ~isempty(reliableTracks)
                % Get bounding boxes.
                bboxes = cat(1, reliableTracks.box);
                
                % Get ids.
                ids = int32([reliableTracks(:).id]);
                
                % membuat label untuk objk yg menunjukkan tampilan prediksi
                % dr pada lokasi sebelumnya.
                labels = cellstr(int2str(ids'));
                predictedTrackInds = ...
                    [reliableTracks(:).consecutiveInvisibleCount] > 0;
                isPredicted = cell(size(labels));
                isPredicted(predictedTrackInds) = {' predicted'};
                labels = strcat(labels, isPredicted);
            end
        end   
%Kalman filter done
   
[yb xb]=size(bboxes);
if (yb>0)

detector= vision.CascadeObjectDetector('platDetectorLBPterbaru.xml');
img2 = rgb2gray(frame);

%bbox pada objek yang terdeteksi
box= step(detector, img2);
%inserting that bounding box in given picture and showing it
[sumbux sumbuy]=size(box);
ab=0;

for i=1:sumbux
    if((box(i,3)>=50) && (box(i,3)<=200))
        if((box(i,4)>=25) && (box(i,4)<=200))
           ab=ab+1;
           c(ab,:)=[box(ab,1) box(ab,2) box(i,3) box(ab,4)];
        end
    end
end

%program untuk menampilkan video dan tulisan "Frame ke-"
axes(handles.videoplay);
set(imshow(insertObjectAnnotation(frame, 'rectangle', bboxes,'Plat')));
title(strcat('Frame ke-',mat2str(dataframe)));

value{4}=[];
[yc xc]=size(c);
for mkpelat=11:yc+10
    z(mkpelat,:)=strcat('f',mat2str(mkpelat));
    value{mkpelat-10}=imcrop(frame,c(mkpelat-10,:));
end

 %program untuk detektor
kandidatpelat=struct(z(11,:),value{1},z(12,:),value{2},z(13,:),value{3});

[ykandidatpelatf11 xkandidatpelatf11]=size(kandidatpelat.f11);
[ykandidatpelatf12 xkandidatpelatf12]=size(kandidatpelat.f12);
[ykandidatpelatf13 xkandidatpelatf13]=size(kandidatpelat.f13);

if((ykandidatpelatf11>0) && (xkandidatpelatf11>0))
    Fungsiocr(kandidatpelat.f11,handles.axes2);
end
if((ykandidatpelatf12>0) && (xkandidatpelatf12>0))
    Fungsiocr(kandidatpelat.f12,handles.axes3);
end
if((ykandidatpelatf13>0) && (xkandidatpelatf13>0))
    Fungsiocr(kandidatpelat.f13,handles.axes4);
end
else  
axes(handles.videoplay);
set(imshow(insertObjectAnnotation(frame, 'rectangle', c,'Plat')));
title(strcat('Frame ke-',mat2str(dataframe)));
end

pause(0.01);
end% userData.stop = true;

% % program tombol close
% function pushbutton3_Callback(hObject, eventdata, handles)
% play_Callback; %pushbutton
% userData = get(handles.TAPelat, 'UserData');
% set(handles.TAPelat,'UserData',userData);
