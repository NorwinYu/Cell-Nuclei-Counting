% Read images and put into a list;
img1 = imread('image/StackNinja1.bmp');
img2 = imread('image/StackNinja2.bmp');
img3 = imread('image/StackNinja3.bmp');
imgList = {img1, img2, img3};

% For loop to process images
for imgList_index = 1: size(imgList,2)
    
    % choose the image
    img = imgList{imgList_index};
    % figure, imshow(img);
    
    % define the number of the cell in two dimensions
    cell_width_number = 4;
    cell_high_number = 2;
    
    % transfer image to cell
    cell_width = (size(img,1)/cell_width_number)*ones(1,cell_width_number);
    cell_high = (size(img,2)/cell_high_number)*ones(1,cell_high_number);
    
    img_cell_list = mat2cell(img, cell_width, cell_high, 3);
    
    img_cell_list_contrast = img_cell_list;
    img_cell_list_noise_reduction = img_cell_list;
    img_cell_list_thresholding = img_cell_list;
    img_cell_list_erosion = img_cell_list;
    
    % For loop to process each cell created of the image
    cell_find_counter = 0;
    
    for j = 1:cell_high_number
        for i = 1:cell_width_number
            
            % choose the image cell
            img_cell = img_cell_list{i, j};
            
            % use contrast stretching
            IsContrastStretchingUsed = 1;
            if (IsContrastStretchingUsed)
               img_cell = intrans(img_cell, 'stretch', mean2(tofloat(img_cell)),20);
            end
            
            img_cell_list_contrast{i, j} = img_cell;
            
            % use noise reduction - gaussian
            IsNoiseReductionGussianUsed = 0;
            if (IsNoiseReductionGussianUsed)
                gaussian_K = 0.5;
                gauss = fspecial('gaussian', [5 5], gaussian_K);
                img_cell = imfilter(img_cell, gauss);
            end
            
            % use noise reduction - contraharmonic mean
            IsNoiseReductionChmeanUsed = 1;
            if (IsNoiseReductionChmeanUsed)
                chmean_q = -3;
                img_cell = spfilt(img_cell, 'chmean', 3, 3, chmean_q);
            end
            
            img_cell_list_noise_reduction{i, j} = img_cell;
            
            % transfer image type unit -> single
            img_cell_float = tofloat(img_cell);
            
            % use optimum global thresholding with Otsu method
            IsOtsuThresholdingUsed = 0;
            if (IsOtsuThresholdingUsed)
                [Tf SMF] = graythresh(img_cell_float);
                img_otsu_thresholding = im2bw(img_cell_float, Tf);
                
                img_cell_float = img_otsu_thresholding;
            end
            
            % use global thresholding with edges - Laplace
            IsEdgesThresholdingUsed = 1;
            if (IsEdgesThresholdingUsed)
                w = [-1 -1 -1; -1 8 -1; -1 -1 -1];
                lap = abs(imfilter(img_cell_float, w, 'replicate'));
                lap = lap/max(lap(:));
                h = imhist(lap);
                Q = percentile2i(h, 0.995);
                markerImage = lap > Q; 
                
                hp = imhist(img_cell_float.*markerImage);
                hp(1) = 0;
                T = otsuthresh(hp);
                img_edges_thresholding= im2bw(img_cell_float, T);
                
                img_cell_float = img_edges_thresholding;
            end
            
            img_cell_list_thresholding{i, j} = img_cell_float;
            
            % use erosion
            IsErosionUsed = 1;
            if (IsErosionUsed)
                erosion_R = 2;
                se = strel('disk', erosion_R);
                img_cell_erosion = imerode(img_cell_float, se);
                
                img_cell_float = img_cell_erosion;
            end
            
            img_cell_list_erosion{i, j} = img_cell_float;
            
            % count found cell number
            [L, num] = bwlabel(img_cell_float, 8);
            cell_find_counter = cell_find_counter + num;
            
            % set result image to image cell
            img_cell_list{i, j} = img_cell_float;
            
            % disp info
            disp("[Finding] width: " + i + " High: " + j + " Found " + num + " cells.");
            
        end
    end
    
    % disp number
    disp("[Result-image" + imgList_index + "] Found " + cell_find_counter + " cells.");
    
    % show result image
    img_result = cell2mat(img_cell_list_contrast);
    % figure, imshow(img_result);
    img_result = cell2mat(img_cell_list_noise_reduction);
    % figure, imshow(img_result);
    img_result = cell2mat(img_cell_list_thresholding);
    % figure, imshow(img_result);
    img_result = cell2mat(img_cell_list_erosion);
    % figure, imshow(img_result);
    img_result = cell2mat(img_cell_list);
    figure, imshow(img_result);
end

