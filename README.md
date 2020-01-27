# Counting Cell Nuclei

2018/03/21

## Introduction

This report describes and analyzes a procedure for automatically detecting the number of nuclei based on the observation of plant root cell microscopy by Matlab.

- Input - a list of the plant root cell microscopies

   ![Screen Shot 2018-03-22 at 4.44.09 am](./pic/Screen Shot 2018-03-22 at 4.44.09 am.png)

- Output - print each cell nuclei number of each image



##Implementation

In this program, a lot of image processing knowledge is used. Listed as follows:

- Intensity Transformation - Contrast Stretching
- Spatial Filtering and Image Reconstruction - Noise Reduction
- Morphological Image Processing - Erosion
- Image Segmentation - Thresholding
- Feature Extraction - Boundary Preprocessing

### Get started

- In the program, the `imread` function is used to read the image and as uint8 format. So It must make sure that the image exists and is placed under the `image` folder in the current directory.

  ```matlab
  image_path = image/StackNinjaX.bmp
  ```

- Some functions in `dipum_toolbox_2.0.2` from the book named `Digital Image Processing Using MATLAB` are called in this program. Decompress the source code and those functions that are used will be stored in the current directory.

  - `percentile2i.p`
  - `tofloat.p`
  - `intrans.p`
  - `spfilt.p`

- Run `cw_psyby2.m`

### Read image 

As mentioned before, the `imread` function is used to import images.

```matlab
% Read images and put into a list;
img1 = imread('image/StackNinja1.bmp');
img2 = imread('image/StackNinja2.bmp');
img3 = imread('image/StackNinja3.bmp');
imgList = {img1, img2, img3};
```

### For loop for each image

Traverse the imageList and select an image as the object to be processed later.

```matlab
% For loop to process images
for imgList_index = 1: size(imgList,2)
    
    % choose the image
    img = imgList{imgList_index};
    
    ......
end
```

### Divide image

Divide the image to be processed to achieve the best results using the `mat2cell` function.

```matlab
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
```

### For loop for each image cell

Traverse each image cell and select one as the object to be processed later.

```matlab
	for j = 1:cell_high_number
        for i = 1:cell_width_number
            
            % choose the image cell
            img_cell = img_cell_list{i, j};
            
            ......
        end
    end
```

### Contrast stretching

Enhancing cell structure by calling the `intrans` function using contrast stretching.

```matlab
            % use contrast stretching
            IsContrastStretchingUsed = 1;
            if (IsContrastStretchingUsed)
               img_cell = intrans(img_cell, 'stretch', mean2(tofloat(img_cell)),20);
            end
            
            img_cell_list_contrast{i, j} = img_cell;
```

- `mean2` Calculate the average value of the image

- `tofloat` Convert the image to a floating point

- `intrans('stretch')` Contrast stretching

  By looking at the source code of the `intran` function, the essence of it is to use the following contrast stretching transformation formula.

  ```matlab
  g = 1./(1 + m./f).^E
  ```

### Noise reduction

Use filters to reduce noise on the image by using `fspecial`  and `spfilt` functions.

```matlab
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
```

- `fspecial` creates Gaussian filters using follow formulas.

  ![Screen Shot 2018-03-22 at 6.47.02 am](./pic/Screen Shot 2018-03-22 at 6.47.02 am.png)

- `spfilt` creates Contraharmonic Mean filters using following code.

  ```matlab
  function f = charmean(g, m, n, q)
  %  Implements a contraharmonic mean filter.
  inclass = class(g);
  g = im2double(g);
  f = imfilter(g.^(q+1), ones(m, n), 'replicate');
  f = f ./ (imfilter(g.^q, ones(m, n), 'replicate') + eps);
  f = changeclass(inclass, f);
  ```

### Transfer image type

```matlab
            % transfer image type unit -> single
            img_cell_float = tofloat(img_cell);
```

### Thresholding

Use edge information based on Laplacian global thresholding to identify the cell nuclei.

```matlab
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
```

### Erosion

Use erosion to clearly identify the cell nuclei and Improve the accuracy of counting cell nuclei number.

```matlab
            % use erosion
            IsErosionUsed = 1;
            if (IsErosionUsed)
                erosion_R = 2;
                se = strel('disk', erosion_R);
                img_cell_erosion = imerode(img_cell_float, se);
                
                img_cell_float = img_cell_erosion;
            end
            
            img_cell_list_erosion{i, j} = img_cell_float;
```

- use `disk`  as the shape of the `strel` function

### Count cell nuclei

Count the number of  8-connected objects using the `bwlabel` function with binary images.

```matlab
            % count found cell number
            [L, num] = bwlabel(img_cell_float, 8);
            cell_find_counter = cell_find_counter + num;
```

### Prompt

```matlab
            % set result image to image cell
            img_cell_list{i, j} = img_cell_float;
            
            % disp info
            disp("[Finding] width: " + i + " High: " + j + " Found " + num + " cells.");
```

### Show results

```matlab
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
```



## Results



## Read image

![Screen Shot 2018-03-22 at 7.31.17 am](./pic/Screen Shot 2018-03-22 at 7.31.17 am.png)



### Divide image

![Screen Shot 2018-03-22 at 7.30.11 am](./pic/Screen Shot 2018-03-22 at 7.30.11 am.png)



### Contrast stretching

- image1

![Screen Shot 2018-03-22 at 7.35.45 am](./pic/Screen Shot 2018-03-22 at 7.35.45 am.png)

- image2

![Screen Shot 2018-03-22 at 7.38.56 am](./pic/Screen Shot 2018-03-22 at 7.38.56 am.png)

- image3

![Screen Shot 2018-03-22 at 7.40.40 am](./pic/Screen Shot 2018-03-22 at 7.40.40 am.png)



### Noise Reduction

- image1

![Screen Shot 2018-03-22 at 7.42.06 am](./pic/Screen Shot 2018-03-22 at 7.42.06 am.png)

- image2

![Screen Shot 2018-03-22 at 7.42.51 am](./pic/Screen Shot 2018-03-22 at 7.42.51 am.png)

- image3

![Screen Shot 2018-03-22 at 7.43.57 am](./pic/Screen Shot 2018-03-22 at 7.43.57 am.png)



### Thresholding

- image1

![Screen Shot 2018-03-22 at 7.46.37 am](./pic/Screen Shot 2018-03-22 at 7.46.37 am.png)

- image2

![Screen Shot 2018-03-22 at 7.47.38 am](./pic/Screen Shot 2018-03-22 at 7.47.38 am.png)

- image3

![Screen Shot 2018-03-22 at 7.48.40 am](./pic/Screen Shot 2018-03-22 at 7.48.40 am.png)



### Erosion

- image1

![Screen Shot 2018-03-22 at 7.49.44 am](./pic/Screen Shot 2018-03-22 at 7.49.44 am.png)

- image2

![Screen Shot 2018-03-22 at 7.50.35 am](./pic/Screen Shot 2018-03-22 at 7.50.35 am.png)

- image3

![Screen Shot 2018-03-22 at 7.51.19 am](./pic/Screen Shot 2018-03-22 at 7.51.19 am.png)



### Prompt

```mathematica
>> cw_psyby2
[Finding] width: 1 High: 1 Found 30 cells.
[Finding] width: 2 High: 1 Found 33 cells.
[Finding] width: 3 High: 1 Found 49 cells.
[Finding] width: 4 High: 1 Found 22 cells.
[Finding] width: 1 High: 2 Found 24 cells.
[Finding] width: 2 High: 2 Found 37 cells.
[Finding] width: 3 High: 2 Found 27 cells.
[Finding] width: 4 High: 2 Found 30 cells.
[Result-image1] Found 252 cells.
[Finding] width: 1 High: 1 Found 5 cells.
[Finding] width: 2 High: 1 Found 62 cells.
[Finding] width: 3 High: 1 Found 38 cells.
[Finding] width: 4 High: 1 Found 0 cells.
[Finding] width: 1 High: 2 Found 2 cells.
[Finding] width: 2 High: 2 Found 79 cells.
[Finding] width: 3 High: 2 Found 44 cells.
[Finding] width: 4 High: 2 Found 0 cells.
[Result-image2] Found 230 cells.
[Finding] width: 1 High: 1 Found 1 cells.
[Finding] width: 2 High: 1 Found 46 cells.
[Finding] width: 3 High: 1 Found 58 cells.
[Finding] width: 4 High: 1 Found 0 cells.
[Finding] width: 1 High: 2 Found 1 cells.
[Finding] width: 2 High: 2 Found 57 cells.
[Finding] width: 3 High: 2 Found 52 cells.
[Finding] width: 4 High: 2 Found 4 cells.
[Result-image3] Found 219 cells.
```



## Reasons why chose those methods

### The reason why divide the image into cells

In the initial version of the program, the image was adjusted using a histogram equalization method instead of contrast stretching. However, when the processing object changes from the first image to the second image, the result of this method is not very close to the ideal data. There must have some differences between these two images, which will lead to such results.

By studying the histograms of the two graphs, it is found that the black background of the second map block affects the effect of the histogram equalization processing.

So, use `img = imcrop(img);` to select the process area.  

![Screen Shot 2018-03-21 at 7.26.51 pm](./pic/Screen Shot 2018-03-21 at 7.26.51 pm.png)

The following four graphs show changes in the histogram equalization before and after the process zone selection. 

![Screen Shot 2018-03-22 at 10.46.50 am](./pic/Screen Shot 2018-03-22 at 10.46.50 am.png)

Obviously, after removing the black background that does not need to be studied, after using the histogram equalization, the improvement effect of the image is significant. 

However, manual selection is not a good solution for a program. With the idea of divide and conquer, these images can be divided into small pieces, and each piece is processed separately and finally recombined. 



### The Reason why use contrast stretching

The use of the technique of contrast stretching can highlight the structure of the cell and highlight the nucleus to be sought. This can be intuitively felt from the comparison of this picture below.

![Screen Shot 2018-03-22 at 7.35.45 am](./pic/Screen Shot 2018-03-22 at 7.35.45 am.png)

The final version of the code abandons the histogram equalization method because it is too susceptible to the overall image. If the program just highlights the object structure in the image, using contrast stretching is more appropriate.



### The reason why use noise reduction

After using the “contrast stretching” method, the image is prone to a large amount of noise, which is most evident in the second and third images.

![Screen Shot 2018-03-22 at 11.23.07 am](./pic/Screen Shot 2018-03-22 at 11.23.07 am.png)

As can be seen from the picture, this is obviously salt and pepper noise, and the program needs to use something like a median filter to process the image.



### The reason why use thresholding

Use thresholding to identify the cell nuclei. 

![Screen Shot 2018-03-22 at 7.46.37 am](./pic/Screen Shot 2018-03-22 at 7.46.37 am.png)



### The reason why use erosion

By using erosion operation, some of the white dots of the connected cells are separated, improving the accuracy of the counting the number.

![Screen Shot 2018-03-22 at 12.09.30 pm](./pic/Screen Shot 2018-03-22 at 12.09.30 pm.png)



## Strengths and weaknesses

### Divide image

**Strengths**

- Mainly through the local pixel image processing, not affected by the overall picture, greatly enhancing the usability of the program processing pictures.

- The quantitative study of the efficiency and feasibility of processing pictures in different segmentation situations by modifying the code.

  ```matlab
      % define the number of the cell in two dimensions
      cell_width_number = 4;
      cell_high_number = 2;
  ```

- The image processing unit, making mass image processing possible. For example, using distributed computing to process large data images.

**Weaknesses**

- This version of the code does the same thing for each unit and does not consider the differences in each block. This will make some forms of segmentation cause less than ideal results.

![Screen Shot 2018-03-22 at 12.36.04 pm](./pic/Screen Shot 2018-03-22 at 12.36.04 pm.png)



### Contrast Stretching

**Strengths**

- Highlight the structure of the cell and highlight the nucleus to be sought

![Screen Shot 2018-03-22 at 7.35.45 am](./pic/Screen Shot 2018-03-22 at 7.35.45 am.png)

**Weaknesses**

- The image is prone to a large amount of noise, which is most evident in the second and third images.

![Screen Shot 2018-03-22 at 11.23.07 am](./pic/Screen Shot 2018-03-22 at 11.23.07 am.png)



### Noise reduction

**Strengths**

- Reduce salt and pepper noise by using the filter.

![Screen Shot 2018-03-22 at 7.43.57 am](./pic/Screen Shot 2018-03-22 at 7.43.57 am.png)

**Weaknesses**

- In the experiment of transforming the segmentation condition, some units could not reduce noise well.



### Erosion

**Strengths**

- some of the white dots of the connected cells are separated, improving the accuracy of the counting the number

![Screen Shot 2018-03-22 at 12.09.30 pm](./pic/Screen Shot 2018-03-22 at 12.09.30 pm.png)

**Weaknesses**

- In the middle of the image, the Erosion does not break off the points where there has many connections between points.

![Screen Shot 2018-03-22 at 1.06.02 pm](./pic/Screen Shot 2018-03-22 at 1.06.02 pm.png)

