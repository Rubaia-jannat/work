function edgeImage = sobelEdgeDetect(image)
    % Assumes 'image' is a 2D grayscale array (e.g., blurred image)

    % Sobel kernels for x and y directions
    Gx = [-1 0 1;
          -2 0 2;
          -1 0 1];

    Gy = [-1 -2 -1;
           0  0  0;
           1  2  1];

    % Convolve with Sobel kernels
    Ix = imfilter(image, Gx, 'replicate');
    Iy = imfilter(image, Gy, 'replicate');

    % Compute edge intensity (gradient magnitude)
    edgeImage = sqrt(Ix.^2 + Iy.^2);
end



