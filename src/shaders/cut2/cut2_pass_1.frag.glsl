/*
 * Cheap Upscaling Triangulation
 *
 * Copyright (c) Filippo Scognamiglio 2024
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define HIGHP highp
#else
#define HIGHP mediump
#endif

#define EPSILON 0.02

precision lowp float;

uniform lowp sampler2D tex0;
uniform lowp sampler2D previousPass;

varying HIGHP vec2 screenCoords;
varying HIGHP vec2 coords;
varying HIGHP vec2 passCoords;
varying HIGHP vec2 c05;
varying HIGHP vec2 c06;
varying HIGHP vec2 c09;
varying HIGHP vec2 c10;

lowp float luma(lowp vec3 v) {
  return v.g;
}

struct Pixels {
  lowp vec3 p0;
  lowp vec3 p1;
  lowp vec3 p2;
  lowp vec3 p3;
};

struct ShapeWeights {
  lowp vec3 weights;
  lowp vec3 midPoints;
};

struct Pattern {
  Pixels pixels;
  lowp vec3 weights;
  lowp vec3 midPoints;
  lowp vec3 baseSharpness;
};

struct Flags {
  bool flip;
  bool triangle;
  lowp vec4 edgeWeight;
};

lowp vec2 quickUnpackFloats2(lowp float value) {
  lowp vec2 result = vec2(0.0);
  lowp float current = value;

  current *= 16.0;
  result.x = floor(current);
  current -= result.x;

  current *= 16.0;
  result.y = floor(current);
  current -= result.y;

  return result / 12.0;
}

bvec2 quickUnpackBools2(lowp float value) {
  lowp vec2 result = vec2(0.0);
  lowp float current = value;

  current *= 2.0;
  result.x = floor(current);
  current -= result.x;

  current *= 2.0;
  result.y = floor(current);
  current -= result.y;

  return greaterThan(result, vec2(0.5));
}

Flags parseFlags(lowp vec3 flagsPixel) {
  Flags flags;
  flags.edgeWeight = clamp(
    vec4(quickUnpackFloats2(flagsPixel.y + 0.001953125), quickUnpackFloats2(flagsPixel.z + 0.001953125)),
    EPSILON,
    1.0 - EPSILON
  );
  bvec2 boolFlags = quickUnpackBools2(flagsPixel.x + 0.125);
  flags.triangle = boolFlags.x;
  flags.flip = boolFlags.y;
  return flags;
}

lowp float linearStep(lowp float edge0, lowp float edge1, lowp float t) {
  return clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
}

lowp float sharpness(lowp float l1, lowp float l2) {
#if USE_DYNAMIC_BLEND
  const lowp float blendDiffInv = 1.0 / (BLEND_MAX_CONTRAST_EDGE - BLEND_MIN_CONTRAST_EDGE);
  lowp float lumaDiff = abs(l1 - l2);
  lowp float contrast = clamp((lumaDiff - BLEND_MIN_CONTRAST_EDGE) * blendDiffInv, 0.0, 1.0);
  lowp float result = mix(BLEND_MIN_SHARPNESS * 0.5, BLEND_MAX_SHARPNESS * 0.5, contrast);
#else
  lowp float result = STATIC_BLEND_SHARPNESS * 0.5;
#endif
  return result;
}

lowp float adjustMidpoint(lowp float x, lowp float midPoint) {
  lowp float result = 0.0;
  result += clamp(x / midPoint, 0.0, 1.0);
  result += clamp((x - midPoint) / (1.0 - midPoint), 0.0, 1.0);
  return 0.5 * result;
}

lowp vec3 blend(lowp vec3 a, lowp vec3 b, lowp float t, lowp float midPoint, lowp float baseSharpness) {
  lowp float sharpness = baseSharpness * sharpness(luma(a), luma(b));
  lowp float nt = adjustMidpoint(t, midPoint);
  nt = clamp((nt - sharpness) / (1.0 - 2.0 * sharpness), 0.0 , 1.0);
  return mix(a, b, nt);
}

Pattern pattern(Pixels pixels, lowp vec4 edgeWeights, bool triangle, lowp vec2 pxCoords) {
  Pattern result;

  bool firstTriangle = triangle && pxCoords.x + pxCoords.y <= 1.0;
  bool secondTriangle = triangle && !firstTriangle;

  lowp vec2 midPoints = vec2(0.0);

  if (secondTriangle) {
    pxCoords = vec2(1.0 - pxCoords.y, 1.0 - pxCoords.x);
    pixels = Pixels(pixels.p3, pixels.p1, pixels.p2, pixels.p0);
    edgeWeights = vec4(1.0) - edgeWeights.yxwz;
  }

  if (triangle) {
    lowp float coordsSum = pxCoords.x + pxCoords.y;
    midPoints = vec2(
    edgeWeights.x * edgeWeights.w * coordsSum / (edgeWeights.w * pxCoords.x + edgeWeights.x * pxCoords.y),
    0.5 + 0.5 * clamp(-edgeWeights.x + edgeWeights.y - edgeWeights.z + edgeWeights.w, -1.0, 1.0)
    );
    pxCoords = vec2(coordsSum, pxCoords.y / coordsSum);
  } else {
    midPoints = vec2(
    mix(edgeWeights.x, edgeWeights.z, pxCoords.y),
    mix(edgeWeights.w, edgeWeights.y, pxCoords.x)
    );
  }

  result.weights = pxCoords.xxy;
  result.midPoints = midPoints.xxy;
  result.baseSharpness = vec3(1.0, 1.0, float(!triangle));
  result.pixels = Pixels(
  pixels.p0,
  pixels.p1,
  triangle ? pixels.p0 : pixels.p2,
  triangle ? pixels.p2 : pixels.p3
  );

  return result;
}

void main() {
  lowp vec3 t05 = texture2D(tex0, c05).rgb;
  lowp vec3 t06 = texture2D(tex0, c06).rgb;
  lowp vec3 t09 = texture2D(tex0, c09).rgb;
  lowp vec3 t10 = texture2D(tex0, c10).rgb;

  lowp vec3 flagsPixel = texture2D(previousPass, passCoords).xyz;
  Flags flags = parseFlags(flagsPixel);
  Pixels pixels = Pixels(t05, t06, t09, t10);

  lowp vec2 pxCoords = fract(screenCoords);
  lowp vec4 edges = flags.edgeWeight;

  if (flags.flip) {
    pixels = Pixels(pixels.p1, pixels.p0, pixels.p3, pixels.p2);
    pxCoords.x = 1.0 - pxCoords.x;
  }

  Pattern pattern = pattern(pixels, edges, flags.triangle, pxCoords);

  lowp vec3 final = blend(
    blend(pattern.pixels.p0, pattern.pixels.p1, pattern.weights.x, pattern.midPoints.x, pattern.baseSharpness.x),
    blend(pattern.pixels.p2, pattern.pixels.p3, pattern.weights.y, pattern.midPoints.y, pattern.baseSharpness.y),
    pattern.weights.z,
    pattern.midPoints.z,
    pattern.baseSharpness.z
  );

  gl_FragColor = vec4(final.rgb, 1.0);
}
