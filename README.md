# Cheap Upscaling Triangulation

Cheap Upscaling Triangulation (CUT) is a family of single-image upscaling algorithms for retro games designed to be:

* **Versatile**: can upscale from and to any image resolution and are applicable to all the 2D and 3D consoles that [Lemuroid](https://github.com/Swordfish90/Lemuroid) supports
* **Efficient**: keep the number of samples and calculations as low as possible in order to minimize battery consumption

In order to achieve this, we need to **CUT some corners**... Literally!

## Algorithms

The family is composed of two algorithms **[CUT1](/algorithms/cut1.md)** and **[CUT2](/algorithms/cut2.md)**, which share the same basic steps:

* Edge Detection
* Triangulation / Pattern Recognition
* Interpolation

These steps are implemented differently in the two algorithms, leading to different quality and performance levels:

* **[CUT1](/algorithms/cut1.md)**: Uses a 2x2 pixel window and can approximate edges of 45°
* **[CUT2](/algorithms/cut2.md)**: Uses a 4x4 pixel window and can approximate edges of  30°, 45° and 60°

## Configuration

The look of both algorithms can be customized with a set of parameters:

```
#define USE_DYNAMIC_BLEND 1          // Dynamically blend color with respect to contrast
#define BLEND_MIN_CONTRAST_EDGE 0.0  // Minimum contrast level at which sharpness starts increasing [0, 1]
#define BLEND_MAX_CONTRAST_EDGE 1.0  // Maximum contrast level at which sharpness stops increasing [0, 1]
#define BLEND_MIN_SHARPNESS 0.0      // Minimum sharpness level [0, 1]
#define BLEND_MAX_SHARPNESS 1.0      // Maximum sharpness level [0, 1]
#define STATIC_BLEND_SHARPNESS 0.5   // Sharpness level used when dynamic blending is disabled [0, 1]
#define EDGE_USE_FAST_LUMA 0         // Use quick luma approximation in edge detection
#define EDGE_MIN_VALUE 0.05          // Minimum luma difference used in edge detection [0, 1]
#define EDGE_MIN_CONTRAST 1.20       // Minimum contrast ratio used in edge detection [1, ∞]
#define LUMA_ADJUST_GAMMA 0          // Correct gamma to better approximate luma human perception
```

## Results

Here you can find some results. On the left you can see the input image, while on the right the image processed with **CUT2**.

||||
|---|---|---|
![](images/final/cut2/cut2-screen-01.jpg) | ![](images/final/cut2/cut2-screen-02.jpg) | ![](images/final/cut2/cut2-screen-03.jpg)
![](images/final/cut2/cut2-screen-04.jpg) | ![](images/final/cut2/cut2-screen-05.jpg) | ![](images/final/cut2/cut2-screen-06.jpg)
![](images/final/cut2/cut2-screen-07.jpg) | ![](images/final/cut2/cut2-screen-08.jpg) | ![](images/final/cut2/cut2-screen-09.jpg)

Here you can find some results of **[CUT1](/algorithms/cut1.md#results)**.

## Performances

There aren't yet extensive performance tests, but I tried measuring GPU load on my device, a Galaxy S21 FE with Snapdragon 888 playing Final Fantasy VI Advance.

|Filter|GPU Utilization|Resolution
|---|---|---|
Bilinear (Lemuroid) | ~1.5% | 160p
HQx2 (Retroarch) | ~2.5% | 320p
**CUT1 (Lemuroid)** | **~3.5%** | **1080p**
HQx4 (Retroarch) | ~4.5% | 640p
**CUT2 (Lemuroid)** | **~6.5%** | **1080p**
xbrz-freescale-multipass (Retroarch) | ~15.0% | 1080p
