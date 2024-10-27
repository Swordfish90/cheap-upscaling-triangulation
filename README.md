# Cheap Upscaling Triangulation

Cheap Upscaling Triangulation (CUT) is a family of single-image upscaling algorithms for retro and modern games designed to be:

* **Versatile**: can upscale from and to any image resolution and are applicable to all the 2D and 3D consoles that [Lemuroid](https://github.com/Swordfish90/Lemuroid) supports
* **Efficient**: keep the number of samples and calculations as low as possible to minimize battery consumption

In order to achieve this, we need to **CUT some corners**... Literally!

## Algorithms

The family is made by three algorithms **CUT1**, **CUT2** and **CUT3**, that share the same fundamental steps:
* **Triangulation**: Inspired by the method in [1], we analyze the luma plane of each 2x2 square to determine whether it has a vertical, horizontal, or diagonal orientation.  For diagonal orientations, we split the square into two triangles.
* **Pattern Recognition**: We examine neighboring samples and the results from the triangulation to create an interpolation function for each side of the square.
* **Interpolation**: Using the triangulation and the side-specific interpolation functions, we interpolate colors within the square or triangles.

The three algorithms have different levels of quality and features:
* **Passes**: Number of passes required to render the final image. Except for the last pass, each step outputs a buffer with the same resolution as the input image.
* **Samples**: Number of texture samples.
* **Angle Resolution**: The minimal angle the algorithm can accurately represent. Using an approach similar to [2], CUT3 can follow these edges more precisely.
* **Soft Edges**: CUT2 and CUT3 enhance the definition of edges wider than one pixel, significantly improving the handling of anti-aliased content.

| Algorithm                    | Passes | Samples                | Angle Resolution | Soft-Edges Handling |
|------------------------------|--------|------------------------|------------------|---------------------|
| **[CUT1](src/shaders/cut1)** | 1      | 4\*O                   | 45               | No                  |
| **[CUT2](src/shaders/cut2)** | 2      | 12\*I + 5\*O           | 30               | Yes                 |
| **[CUT3](src/shaders/cut3)** | 3      | 12\*I + 4\*D\*I + 5\*O | Configurable     | Yes                 |

* I: Input image resolution
* O: Output image resolution
* D: Edge search distance in each direction (tied to angle resolution)

## Results

Check a simple webapp that applies the filters to some game screenshots:

[https://swordfish90.github.io/cheap-upscaling-triangulation/](https://swordfish90.github.io/cheap-upscaling-triangulation/)

## Configuration

The look of every variant can be customized with a set of parameters:

```glsl
// Available in CUT1, CUT2 and CUT3
#define USE_DYNAMIC_BLEND 1                 // Dynamically blend color with respect to contrast
#define BLEND_MIN_CONTRAST_EDGE 0.0         // Minimum contrast level at which sharpness starts increasing [0, 1]
#define BLEND_MAX_CONTRAST_EDGE 1.0         // Maximum contrast level at which sharpness stops increasing [0, 1]
#define BLEND_MIN_SHARPNESS 0.0             // Minimum sharpness level [0, 1]
#define BLEND_MAX_SHARPNESS 1.0             // Maximum sharpness level [0, 1]
#define STATIC_BLEND_SHARPNESS 0.5          // Sharpness level used when dynamic blending is disabled [0, 1]
#define EDGE_USE_FAST_LUMA 0                // Use quick luma approximation in edge detection
#define EDGE_MIN_VALUE 0.05                 // Minimum luma difference used in edge detection [0, 1]

// Available in CUT2 and CUT3
#define SOFT_EDGES_SHARPENING 1             // Enable soft-edges sharpening
#define SOFT_EDGES_SHARPENING_AMOUNT 0.75   // Maximum size reduction of soft-edges pixels (antialiased pixels) [0, 1]

// Available in CUT3
#define SEARCH_MIN_CONTRAST 0.5             // Minimum relative contrast for search to include current pattern [0, 1]
#define SEARCH_MAX_DISTANCE 8               // Maximum search distance in each direction (N,E,S,W) to find a continuous edge [1, ∞[
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
