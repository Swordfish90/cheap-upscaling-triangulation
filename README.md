# Cheap Upscaling Triangulation

Cheap Upscaling Triangulation (CUT) is a family of single-image upscaling algorithms for retro and modern games designed to be:

* **Versatile**: can upscale from and to any image resolution and are applicable to all the 2D and 3D consoles that [Lemuroid](https://github.com/Swordfish90/Lemuroid) supports
* **Efficient**: keep the number of samples and calculations as low as possible to minimize battery consumption

In order to achieve this, we need to **CUT some corners**... Literally!

## Algorithms

The family is composed of three algorithms **CUT1**, **CUT2** and **CUT3**, which share the same basic steps:

* **Edge Detection**
* **Triangulation / Pattern Recognition**
* **Interpolation**

The three implementations are very different leading to different level of quality and performances. Here's the most critical differences:
* **Passes**: Number of passes required to render the final image
* **Samples**: Number of texture samples used from the original image
* **Angle Resolution**: The minimal angle the algorithm is able to correctly represent. CUT3 is also able to follow edges up to a configurable distance to correctly approximate all kinds of inclinations.
* **Soft Edges**: CUT2 and CUT3 are also able to improve the definition of edges which are wider than one pixel. This greatly helps with anti-aliased content.

| Algorithm                            | Passes | Samples | Angle Resolution | Soft-Edges Handling |
|--------------------------------------|--------|---------|------------------|---------------------|
| CUT1                                 | 1      | 4       | 45               | No                  |
| CUT2                                 | 2      | 12      | 30               | Yes                 |
| CUT3                                 | 3      | 12      | Configurable     | Yes                 |

## Results

Here you can check a simple webapp that applies the filters on a set of game screenshots.

## Configuration

The look of both versions can be customized with a set of parameters:

```glsl
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

## Performances

There aren't yet extensive performance tests, but I tried measuring GPU load on my device, a Galaxy S21 FE with Snapdragon 888 playing Final Fantasy VI Advance.

| Filter                               | GPU Utilization | Resolution |
|--------------------------------------|-----------------|------------|
| Bilinear (Lemuroid)                  | ~1.5%           | 160p       |
| HQx2 (Retroarch)                     | ~2.5%           | 320p       |
| **CUT1 (Lemuroid)**                  | **~3.5%**       | **1080p**  |
| HQx4 (Retroarch)                     | ~4.5%           | 640p       |
| **CUT2 (Lemuroid)**                  | **~5.5%**       | **1080p**  |
| **CUT3 (Lemuroid)**                  | **~6.5%**       | **1080p**  |
| xbrz-freescale-multipass (Retroarch) | ~15.0%          | 1080p      |

## References

* [1] D. Su and P. Willis, "**Image interpolation by pixel level data-dependent triangulation**", Computer Graphics Forum, pp. 23, 2004.
* [2] A. Reshetov, "**Morphological antialiasing**", Proceedings of the Conference on High Performance Graphics 2009, pp. 109-116, 2009.
