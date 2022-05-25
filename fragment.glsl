/**
* MIT License
* 
* Copyright (c) 2022 Filippo Scognamiglio
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
**/

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define HIGHP highp
#else
#define HIGHP mediump
#endif

precision mediump float;

#define USE_DYNAMIC_SHARPNESS 1 // Set to 1 to use dynamic sharpening
#define USE_SHARPENING_BIAS 1 // Set to 1 to bias the interpolation towards sharpening
#define DYNAMIC_SHARPNESS_MIN 0.10 // Minimum amount of sharpening in range [0.0, 0.5]
#define DYNAMIC_SHARPNESS_MAX 0.30 // Maximum amount of sharpening in range [0.0, 0.5]
#define STATIC_SHARPNESS 0.2 // If USE_DYNAMIC_SHARPNESS is 0 apply this static sharpness

uniform lowp sampler2D texture;
uniform HIGHP vec2 textureSize;

varying HIGHP vec2 screenCoords;

lowp float luma(lowp vec3 v) {
  return v.g;
}

lowp float linearStep(lowp float edge0, lowp float edge1, lowp float t) {
  return clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
}

lowp float sharpSmooth(lowp float t, lowp float sharpness) {
  return linearStep(sharpness, 1.0 - sharpness, t);
}

lowp vec3 quadBilinear(lowp vec3 a, lowp vec3 b, lowp vec3 c, lowp vec3 d, lowp vec2 p, lowp float sharpness) {
  lowp float x = sharpSmooth(p.x, sharpness);
  lowp float y = sharpSmooth(p.y, sharpness);
  return mix(mix(a, b, x), mix(c, d, x), y);
}

// Fast computation of barycentric coordinates only in the sub-triangle 1 2 4
lowp vec3 fastBarycentric(lowp vec2 p, lowp float sharpness) {
  lowp float l0 = sharpSmooth(1.0 - p.x - p.y, sharpness);
  lowp float l1 = sharpSmooth(p.x, sharpness);
  return vec3(l0, l1, 1.0 - l0 - l1);
}

lowp vec3 triangleInterpolate(lowp vec3 t1, lowp vec3 t2, lowp vec3 t3, lowp vec3 t4, lowp vec2 c, lowp float sharpness) {
  // Alter colors and coordinates to compute the other triangle.
  bool altTriangle = 1.0 - c.x < c.y;
  lowp vec3 cornerColor = altTriangle ? t3 : t1;
  lowp vec2 triangleCoords = altTriangle ? vec2(1.0 - c.y, 1.0 - c.x) : c;
  lowp vec3 weights = fastBarycentric(triangleCoords, sharpness);
  return weights.x * cornerColor + weights.y * t2 + weights.z * t4;
}

void main() {
  HIGHP vec2 relativeCoords = floor(screenCoords);
  mediump vec2 c1 = ((relativeCoords + vec2(0.0, 0.0)) + vec2(0.5)) / textureSize;
  mediump vec2 c2 = ((relativeCoords + vec2(1.0, 0.0)) + vec2(0.5)) / textureSize;
  mediump vec2 c3 = ((relativeCoords + vec2(1.0, 1.0)) + vec2(0.5)) / textureSize;
  mediump vec2 c4 = ((relativeCoords + vec2(0.0, 1.0)) + vec2(0.5)) / textureSize;

  lowp vec3 t1 = texture2D(texture, c1).rgb;
  lowp vec3 t2 = texture2D(texture, c2).rgb;
  lowp vec3 t3 = texture2D(texture, c3).rgb;
  lowp vec3 t4 = texture2D(texture, c4).rgb;

  lowp float l1 = luma(t1);
  lowp float l2 = luma(t2);
  lowp float l3 = luma(t3);
  lowp float l4 = luma(t4);

#if USE_DYNAMIC_SHARPNESS
  lowp float lmax = max(max(l1, l2), max(l3, l4));
  lowp float lmin = min(min(l1, l2), min(l3, l4));
  lowp float contrast = (lmax - lmin) / (lmax + lmin + 0.05);
#if USE_SHARPENING_BIAS
  contrast = sqrt(contrast);
#endif
  lowp float sharpness = mix(DYNAMIC_SHARPNESS_MIN, DYNAMIC_SHARPNESS_MAX, contrast);
#else
  const lowp float sharpness = STATIC_SHARPNESS;
#endif

  lowp vec2 pxCoords = fract(screenCoords);

  lowp float diagonal1Strength = abs(l1 - l3);
  lowp float diagonal2Strength = abs(l2 - l4);

  // Alter colors and coordinates to compute the other triangulation.
  bool altTriangulation = diagonal1Strength < diagonal2Strength;

  lowp vec3 cd = triangleInterpolate(
    altTriangulation ? t2 : t1,
    altTriangulation ? t3 : t2,
    altTriangulation ? t4 : t3,
    altTriangulation ? t1 : t4,
    altTriangulation ? vec2(pxCoords.y, 1.0 - pxCoords.x) : pxCoords,
    sharpness
  );

  lowp float minDiagonal = min(diagonal1Strength, diagonal2Strength);
  lowp float maxDiagonal = max(diagonal1Strength, diagonal2Strength);
  bool diagonal = minDiagonal * 4.0 + 0.05 < maxDiagonal;

  lowp vec3 final = diagonal ? cd : quadBilinear(t1, t2, t4, t3, pxCoords, sharpness);

  gl_FragColor = vec4(final, 1.0);
};
