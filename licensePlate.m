% Step 1: Read the Image
imagePath = 'double.jpg';
originalImage = imread(imagePath);

% Step 2: Preprocess the Image
% Convert to grayscale
grayImage = rgb2gray(originalImage);

% Apply Gaussian smoothing to reduce noise
smoothedImage = imgaussfilt(grayImage, 1);

% Enhance contrast
enhancedImage = imadjust(smoothedImage);

% Use adaptive thresholding to binarize the image
binaryImage = imbinarize(enhancedImage, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.5);

% Fill holes in the binary image
filledImage = imfill(binaryImage, 'holes');

% Remove small objects
cleanedImage = bwareaopen(filledImage, 100);

% Find edges using Canny edge detector
edgesImage = edge(cleanedImage, 'Canny', [0.02 0.1], 2);

% Step 3: Find Connected Components
cc = bwconncomp(edgesImage);

% Step 4: Filter Connected Components
stats = regionprops(cc, 'Area', 'BoundingBox');
threshold = 200;  % Adjust the area threshold as needed
aspectRatioThreshold = 52/11;  % Adjust the aspect ratio threshold as needed
intensityThreshold = 30;  % Adjust the intensity threshold as needed

filteredStats = [];
for i = 1:length(stats)
    if stats(i).Area > threshold
        aspectRatio = stats(i).BoundingBox(3) / stats(i).BoundingBox(4);
        
        % Get the region within the bounding box
        x = round(stats(i).BoundingBox(1));
        y = round(stats(i).BoundingBox(2));
        width = round(stats(i).BoundingBox(3));
        height = round(stats(i).BoundingBox(4));
        
        region = grayImage(y:y+height-1, x:x+width-1);

        % Compute the mean intensity
        meanIntensity = mean(region(:));

        % Adjust the tolerance as needed
        if abs(aspectRatio - aspectRatioThreshold) < 1 && meanIntensity > intensityThreshold
            filteredStats = [filteredStats; stats(i)];
        end
    end
end

% Step 5: Display the Original Image with Detected Rectangle
figure;
subplotLength = size(filteredStats, 1) + 1;
subplot(subplotLength, 1, 1);
imshow(originalImage);
hold on;

detectedRectangles = [];  % Initialize an empty array to store rectangle information

for i = 1:length(filteredStats)
    rectangleInfo = filteredStats(i).BoundingBox;
    detectedRectangles = [detectedRectangles; rectangleInfo];
    rectangle('Position', rectangleInfo, 'EdgeColor', 'r', 'LineWidth', 2);
end
hold off;

% Step 6: Process the Detected Rectangles
subplotIndex = 2;
for i = 1:size(detectedRectangles, 1)
    % Extract each rectangle
    rect = detectedRectangles(i, :);

    % Crop the region of interest (ROI) from the original image
    roi = imcrop(originalImage, rect);

    % Preprocess the ROI
    grayROI = rgb2gray(roi);
    smoothedROI = imgaussfilt(grayROI, 1);
    enhancedROI = imadjust(grayROI);
    binaryROI = imbinarize(enhancedROI, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.2);

    % Further processing on the cropped ROI
    F = imresize(binaryROI, 1);
    subplot(subplotLength, 1, subplotIndex);
    subplotIndex = subplotIndex + 1;
    imshow(F);

    % OCR on the ROI
    M = ocr(F, 'TextLayout', 'Block', 'Language', 'English');

    % Filter out characters that are not in the valid character set
    validCharacterSet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    filteredText = '';
    for j = 1:length(M.Text)
        if ismember(M.Text(j), validCharacterSet)
            filteredText = [filteredText, M.Text(j)];
        end
    end

    % Display the filtered license plate text
    fprintf('License Plate detected\n');
    disp(filteredText)
end
