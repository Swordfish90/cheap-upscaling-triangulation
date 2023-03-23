# CUT2

We sample a 4x4 window excluding the corner pixels. To make it more efficient, we're only going to look at the luma plane.

```
       P01 -- P02
        |      |
P04 -- P05 -- P06 -- P07
 |      |      |      |
P08 -- P09 -- P10 -- P11
        |      |
       P13 -- P14
```

## Luma extraction

For each pixel, we extract the luma value with the following:

```glsl
lowp float luma(lowp vec3 v) {
#if EDGE_USE_FAST_LUMA
  lowp float result = v.g;
#else
  lowp float result = dot(v, vec3(0.299, 0.587, 0.114));
#endif
#if LUMA_ADJUST_GAMMA
  result = sqrt(result);
#endif
  return result;
}
```

By using ```EDGE_USE_FAST_LUMA```, we can make this step faster by simply relying on the green channel as an approximation.
We can also use ```LUMA_ADJUST_GAMMA``` if we want a more accurate representation of what the human perception is.

## Edge detection

We are able to detected edges of 30°, 45° and 60°.

Standard edge detection algorithms work, but since we're dealing with images that have basically no noise, a slightly different approach delivers better results.

We detect an edge when the minimum luma difference across the edge is greater than the maximum luma difference not crossing said edge.

### Edges with slope of two (30°/60°)

We need to look at every 2x3 and 3x2 block of pixels. Let's take a concrete example:

```
A -- B
|    |
C -- D
|    |
E -- F
```

This block can have two edges: ```AF``` or ```BE```. We're going to define a function that uses the previous idea to look for the edge ```AF```.

Since the extremes can belong to either the left or the right sub-triangles we need to keep track of it. This information will later be used to choose on which colors we're going to interpolate.

```glsl
bvec2 hasEdge(lowp float a, lowp float b, lowp float c, lowp float d, lowp float e, lowp float f) {
  lowp float dab = distance(a, b);
  lowp float dac = distance(a, c);
  lowp float dbc = distance(b, c);
  lowp float dbd = distance(b, d);
  lowp float dcd = distance(c, d);
  lowp float dce = distance(c, e);
  lowp float ddf = distance(d, f);
  lowp float ded = distance(e, d);
  lowp float def = distance(e, f);

  lowp float leftInnerContrast = maxOf(dac, dce, def, dbd);
  lowp float leftOuterContrast = minOf(dab, dcd, ddf, ded);
  bool leftCut = max(EDGE_MIN_CONTRAST * leftInnerContrast, EDGE_MIN_VALUE) < leftOuterContrast;

  lowp float rightInnerContrast = maxOf(dab, dbd, ddf, dce);
  lowp float rightOuterContrast = minOf(dac, dcd, def, dbc);
  bool rightCut = max(EDGE_MIN_CONTRAST * rightInnerContrast, EDGE_MIN_VALUE) < rightOuterContrast;

  return bvec2(leftCut || rightCut, leftCut);
}
```

### Edges with slope of one (45°)

We can look at the center square:

```
A -- B
|    |
C -- D
```

Using a similar reasoning, we can detect an edge when ```A``` and ```D``` are similar to each other, but much different from either ```B``` or ```C```.

```glsl
bool hasEdge(lowp float a, lowp float b, lowp float c, lowp float d) {
  lowp float diff1 = distance(a, d);
  lowp float diff2 = max(
    min(distance(a, b), distance(b, d)),
    min(distance(a, c), distance(c, d))
  );
  return max(EDGE_MIN_CONTRAST * diff1, EDGE_MIN_VALUE) < diff2;
}
```

Detecting both edges leads to a valid saddle scenario. We can discriminate between the two by considering the neighborhood and align to the stronger diagonal:

```glsl
if (d05_10 && d06_09) {
  lowp float diff1 = distance(l06, l01) + distance(l11, l06) + distance(l09, l04) + distance(l14, l09);
  lowp float diff2 = distance(l05, l02) + distance(l08, l05) + distance(l10, l07) + distance(l13, l10);
  d05_10 = diff1 + EPSILON < diff2;
  d06_09 = diff2 + EPSILON < diff1;
}
```

## Triangulation / Pattern Recognition

Let's now focus on the center square:

```
P05 -- P06
|       |
P09 -- P10
```

Considering the edges that we found in the previous step and ignoring symmetries, we're extremely likely to fall into one of these patterns: 

||||
|---|---|---|
![](../images/algorithm/patterns/0.svg) | ![](../images/algorithm/patterns/1.svg) | ![](../images/algorithm/patterns/2.svg)
![](../images/algorithm/patterns/3.svg) | ![](../images/algorithm/patterns/4.svg) | ![](../images/algorithm/patterns/5.svg)

Every other scenario can be transformed into one of the previous by flipping it along these axes:
* ```x = 0.5```
* ```y = 0.5```
* ```y = x```

For each pattern, we defined a set of rules that will choose a shape and two segments on which we'll perform the interpolation:

```glsl
struct Pixels {
  lowp vec3 p0;
  lowp vec3 p1;
  lowp vec3 p2;
  lowp vec3 p3;
};

struct Pattern {
  Pixels pixels;
  bool triangle;
  lowp vec2 coords;
};
```

Here the segments are ```P0-P1``` and ```P2-P3```.

## Interpolation

Let's now assume we have ```blend(A, B, t)``` function that mixes two colors given an interpolation parameter.

We can simply use the output of the previous step to perform a bilinear interpolation on the two segments we found earlier:

```glsl
lowp vec3 weights = pattern.triangle ? triangle(pattern.coords) : quad(pattern.coords);

lowp vec3 final = blend(
  blend(pattern.pixels.p0, pattern.pixels.p1, weights.x),
  blend(pattern.pixels.p2, pattern.pixels.p3, weights.y),
  weights.z
);
```

The goal is to have smooth gradients and sharp edges, so we can define the ```blend(A, B, t)``` function as something that looks like a step when the contrast is high, and a linear interpolation when it's low.

```glsl
lowp float linearStep(lowp float edge0, lowp float edge1, lowp float t) {
  return clamp((t - edge0) / (edge1 - edge0 + EPSILON), 0.0, 1.0);
}

lowp float sharpSmooth(lowp float t, lowp float sharpness) {
  return linearStep(sharpness, 1.0 - sharpness, t);
}

lowp float sharpness(lowp float l1, lowp float l2) {
  lowp float lumaDiff = abs(l1 - l2);
  lowp float contrast = linearStep(BLEND_MIN_CONTRAST_EDGE, BLEND_MAX_CONTRAST_EDGE, lumaDiff);
  lowp float result = mix(BLEND_MIN_SHARPNESS * 0.5, BLEND_MAX_SHARPNESS * 0.5, contrast);
  return result;
}

lowp vec3 blend(lowp vec3 a, lowp vec3 b, lowp float t) {
  return mix(a, b, sharpSmooth(t, sharpness(luma(a), luma(b))));
}
```

## Results

Here you can find some results. Each image is split in two, with the left side unprocessed and the right side with **CUT2** applied.

||||
|---|---|---|
![](../images/final/cut2/cut2-screen-01.jpg) | ![](../images/final/cut2/cut2-screen-02.jpg) | ![](../images/final/cut2/cut2-screen-03.jpg)
![](../images/final/cut2/cut2-screen-04.jpg) | ![](../images/final/cut2/cut2-screen-05.jpg) | ![](../images/final/cut2/cut2-screen-06.jpg)
![](../images/final/cut2/cut2-screen-07.jpg) | ![](../images/final/cut2/cut2-screen-08.jpg) | ![](../images/final/cut2/cut2-screen-09.jpg)
