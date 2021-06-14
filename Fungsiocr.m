function colorImage=Fungsiocr(datacitrargb,dataaxes)

colorImage=datacitrargb;
%Save Sementara
%citra = dir(fullfile(pwd,'*.jpg'));
%imwrite(datacitrargb,strcat('data',mat2str(length(citra)),'.jpg'));

%Konversi RGB ke Grayscale
Img_Awal = rgb2gray(colorImage);
%Seragamkan Citra Menjadi Ukuran 200 px X 600 px
I=imresize(Img_Awal,[200 600]);

%Menguatkan Bagian Yang Berwarna Gelap dengan Strel 15
Icorrected = imtophat(I, strel('disk', 15));
%Menguatkan Citra Citra Gelap
BW1 = imadjust(Icorrected);
%Menguatkan Citra Citra Gelap
%BW1 = imadjust(I);
% a= graythresh(I);
BW1 = im2bw(BW1);
% bww = imerode(BW1,strel('square',5));

%Maksimal Blob Yang Diambil 
blobAnalyzer = vision.BlobAnalysis('MaximumCount', 50);

%menjalankan analisis blob
[area, centroids, roi] = step(blobAnalyzer, BW1);

% Cari Area Blob yang Berisi diatas 800 px Warna Hitam / Bernilai 1
areaConstraint = area > 400;

% Update data ROI yang Hanya diatas 200 px per blob
roi = double(roi(areaConstraint, :));

% Compute the aspect ratio.
width  = roi(:,2);
height = roi(:,4);
aspectRatio = width ./ height;

% Cari Rasio Tiap Karakter dengan Nilai Range 0.2-1.0
roi = roi(aspectRatio > 0.10 & aspectRatio < 1 ,:);

% % Size ROI
[yroi xroi]=size(roi);

%Membuat Var Mask Seukuran Gambar Hasil Image Processing
mask = zeros(size(BW1));
for mulaiyroi=1:yroi
    
% format ppbMasking yang digunakan mask(Top:Bottom,Left:Right)
    mask(roi(mulaiyroi,2):roi(mulaiyroi,2)+roi(mulaiyroi,4)-1,...
        roi(mulaiyroi,1):roi(mulaiyroi,1)+roi(mulaiyroi,3)-1) = 1;
end

% %Menampilkan Gambar Hasil Image Processing Ke dalam Masking
img_baru = logical(BW1) .* logical(mask);

%Rekognisi karakter teks,  direktori data train
results = ocr(img_baru,'Language', ...
    {'D:\TA_Paling Terbaru\OCR Paling Terbaru 2\pelat\pelat\tessdata\pelat.traineddata'});

%Hilangkan spasi pada teks
% final_output=final_output(~isspace(final_output))
%Buat Var Final_Output
final_output=[];
final_output=[final_output deblank(results.Text)];

axes(dataaxes);
imshow(Img_Awal);
disp(final_output);
title(strcat('Pelat : ',final_output));

