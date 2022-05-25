# Cheap Upscaling Triangulation

Cheap Upscaling Triangulation (CUT) is a simple, single-image upscaling algorithm for retro games designed to be:

* **Versatile**: it can upscale from and to any image resolution and is applicable to all the 2D and 3D consoles that [Lemuroid](https://github.com/Swordfish90/Lemuroid) supports
* **Efficient**: battery consumption is very critical on mobile devices, so it leverages the GPU and keeps the number of samples and calculations as low as possible

In order to achieve this, we need to **CUT some corners**... Literally!

## Algorithm

### The Intuition

The first [Pixel-Art scaling algorithms](https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms) were cutting corners of input pixels when the two neighbors had the same colors. This smoothed out 45° and 135° straight lines increasing the perceived resolution. Can we extend the idea in continuous space and make it fast?

The first implementation of CUT was actually doing this, but it started to show its limits with newer consoles. The solution needed to be more generic.

### Triangulation

Triangulation is often used when upscaling images. In CUT, for each output pixel, we sample the 2x2 neighborhood and, compute the luminance of these four input pixels.

When the difference in luminosity on one diagonal is much smaller compared to the other, we cut the pixel on that diagonal, creating two triangles.

|Input Image|Triangulated Pixels|Chosen Triangulation|
|---|---|---|
![](images/algorithm/nearest/step1.jpg) | ![](images/algorithm/nearest/step2.jpg) | ![](images/algorithm/nearest/step3.jpg)

### Interpolation

The output of the first step is a series of triangles and squares, where each vertex is associated with an input pixel color. We can mix these colors using standard [bilinear interpolation](https://en.wikipedia.org/wiki/Bilinear_interpolation) on squares and [barycentric coordinates](https://en.wikipedia.org/wiki/Barycentric_coordinate_system) interpolation on triangles.

Changing the interpolation function provides different levels of sharpness. You can see here the difference between two extremes: step and linear interpolations.

|Triangulation|Step Interpolation|Linear Interpolation|
|---|---|---|
![](images/algorithm/nearest/step4.jpg) | ![](images/algorithm/nearest/step5.jpg) | ![](images/algorithm/nearest/step6.jpg)

### Dynamic Sharpness

When looking at 8-bit Pixel-Art, we definitely want these edges to be as sharp as possible, but as we start moving to 16-bit, gradients and bitmaps start to look noisy.

CUT tries to solve this by measuring local contrast using the [Michelson formula](https://en.wikipedia.org/wiki/Contrast_(vision)#Michelson_contrast) on the input pixels and adjusts the interpolation function to produce sharper edges where the contrast is high and smoother edges where it's low.

This increases the perceived resolution on edges, limiting noise or bands in gradients. These sharpness values can be tailored to the content displayed.

|Input|CUT (Static Sharpness)|CUT (Dynamic Sharpness)|
|---|---|---|
![](images/algorithm/dynamic/step1-nearest.jpg) | ![](images/algorithm/dynamic/step2-sharp.jpg) | ![](images/algorithm/dynamic/step3.jpg)

## Implementation

The implementation is provided as a GLSL shader, and it comes with a couple of useful optimizations:
* Instead of computing barycentric coordinates for the two triangles of each of the two triangulation, we move coordinates and points so that only one is calculated for each output fragment
* Instead of computing the luminosity of each input pixel, we take the green channel, which provides a good enough estimate and saves us four dot products

The shader exposes a few parameters which can be used to customize the behaviour:

```
#define USE_DYNAMIC_SHARPNESS 1 // Set to 1 to use dynamic sharpening
#define USE_SHARPENING_BIAS 1 // Set to 1 to bias the interpolation towards sharpening
#define DYNAMIC_SHARPNESS_MIN 0.10 // Minimum amount of sharpening in range [0.0, 0.5]
#define DYNAMIC_SHARPNESS_MAX 0.30 // Maximum amount of sharpening in range [0.0, 0.5]
#define STATIC_SHARPNESS 0.2 // If USE_DYNAMIC_SHARPNESS is 0 apply this static sharpness
```

## Results

Here you can find some results. The left part of the image is obtained with standard nearest-neighbor interpolation, while the right side is computed using two profiles of CUT:
* For 2D games: (DYNAMIC_SHARPNESS_MIN: 0.10, DYNAMIC_SHARPNESS_MAX: 0.30)
* For 3D games: (DYNAMIC_SHARPNESS_MIN: 0.00, DYNAMIC_SHARPNESS_MAX: 0.25)

||||
|---|---|---|
![](images/final/example1.jpg) | ![](images/final/example2.jpg) | ![](images/final/example3.jpg)
![](images/final/example4.jpg) | ![](images/final/example5.jpg) | ![](images/final/example6.jpg)
![](images/final/example7.jpg) | ![](images/final/example8.jpg) | ![](images/final/example9.jpg)

## Performances

There aren't yet extensive performance tests, but I tried measuring GPU load on my device, a Galaxy S21 FE with Snapdragon 888 playing Final Fantasy VI Advance.

|Filter|GPU Utilization|Resolution|Note
|---|---|---|---|
Bilinear (Lemuroid) | ~0.8% | 1080p | --
CRT (Lemuroid) | ~1.0% | 1080p | --
**CUT (Lemuroid)** | **~1.5%** | **1080p** | --
HQx2 (Retroarch) | ~1.5% | 320p | Fixed Resolution Increase of 2x
HQx4 (Retroarch) | ~2.5% | 640p | Fixed Resolution Increase of 4x
xbrz-freescale-multipass (Retroarch) | ~6.0% | 1080p | Best image quality on 2D content
xbrz-freescale (Retroarch) | ~15% | 1080p | Best image quality on 2D content
