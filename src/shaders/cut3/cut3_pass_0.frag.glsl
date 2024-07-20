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

varying HIGHP vec2 c01;
varying HIGHP vec2 c02;
varying HIGHP vec2 c04;
varying HIGHP vec2 c05;
varying HIGHP vec2 c06;
varying HIGHP vec2 c07;
varying HIGHP vec2 c08;
varying HIGHP vec2 c09;
varying HIGHP vec2 c10;
varying HIGHP vec2 c11;
varying HIGHP vec2 c13;
varying HIGHP vec2 c14;

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

lowp float quickPackBools2(bvec2 values) {
  return dot(vec2(values), vec2(0.5, 0.25));
}

lowp float quickPackFloats2(lowp vec2 values) {
  return dot(floor(values * vec2(12.0) + vec2(0.5)), vec2(0.0625, 0.00390625));
}

lowp int findPattern(lowp vec4 values, lowp vec2 saddleAdjustments) {
  lowp vec4 edgesDifferences = abs(values.xxyz - values.yzww);

  lowp vec4 patternContrasts = vec4(
    edgesDifferences.x + edgesDifferences.w,
    edgesDifferences.y + edgesDifferences.z,
    max(edgesDifferences.x + edgesDifferences.z, edgesDifferences.y + edgesDifferences.w),
    max(edgesDifferences.x + edgesDifferences.y, edgesDifferences.z + edgesDifferences.w)
  );

  patternContrasts.zw += clamp((saddleAdjustments.xy - saddleAdjustments.yx) * 0.125, vec2(-0.10), vec2(0.05));

  lowp float maxContrast = max(
    max(patternContrasts.x, patternContrasts.y),
    max(patternContrasts.z, patternContrasts.w)
  );

  bvec4 isMax = greaterThanEqual(patternContrasts, vec4(maxContrast - EPSILON));
  bool isSaddle = all(isMax);

  if (maxContrast < EDGE_MIN_VALUE || isSaddle) {
    return 0;
  } else if (isMax.x) {
    return 1;
  } else if (isMax.y) {
    return 2;
  } else if (isMax.z) {
    return 3;
  } else if (isMax.w) {
    return 4;
  }

  return 0;
}

lowp float softEdgeWeight(lowp float a, lowp float b, lowp float c, lowp float d) {
  lowp float result = 0.0;
  result += clamp(abs((2.0 * b - (a + c))) / abs(a - c), 0.0, 1.0);
  result -= clamp(abs((2.0 * c - (d + b))) / abs(b - d), 0.0, 1.0);
  return clamp(result, -1.0, 1.0);
}

void main() {
  lowp vec3 t01 = texture2D(tex0, c01).rgb;
  lowp vec3 t02 = texture2D(tex0, c02).rgb;
  lowp vec3 t04 = texture2D(tex0, c04).rgb;
  lowp vec3 t05 = texture2D(tex0, c05).rgb;
  lowp vec3 t06 = texture2D(tex0, c06).rgb;
  lowp vec3 t07 = texture2D(tex0, c07).rgb;
  lowp vec3 t08 = texture2D(tex0, c08).rgb;
  lowp vec3 t09 = texture2D(tex0, c09).rgb;
  lowp vec3 t10 = texture2D(tex0, c10).rgb;
  lowp vec3 t11 = texture2D(tex0, c11).rgb;
  lowp vec3 t13 = texture2D(tex0, c13).rgb;
  lowp vec3 t14 = texture2D(tex0, c14).rgb;

  lowp float l01 = luma(t01);
  lowp float l02 = luma(t02);
  lowp float l04 = luma(t04);
  lowp float l05 = luma(t05);
  lowp float l06 = luma(t06);
  lowp float l07 = luma(t07);
  lowp float l08 = luma(t08);
  lowp float l09 = luma(t09);
  lowp float l10 = luma(t10);
  lowp float l11 = luma(t11);
  lowp float l13 = luma(t13);
  lowp float l14 = luma(t14);

  lowp vec2 diagonals = vec2(
    abs(l08 - l05) + abs(l13 - l10) + abs(l10 - l07) + abs(l05 - l02),
    abs(l06 - l01) + abs(l09 - l04) + abs(l11 - l06) + abs(l14 - l09)
  );

  lowp int pattern = findPattern(vec4(l05, l06, l09, l10), diagonals);

  lowp ivec4 neighbors = ivec4(
    findPattern(vec4(l01, l02, l05, l06), vec2(0.0)),
    findPattern(vec4(l06, l07, l10, l11), vec2(0.0)),
    findPattern(vec4(l09, l10, l13, l14), vec2(0.0)),
    findPattern(vec4(l04, l05, l08, l09), vec2(0.0))
  );

  bool vertical = neighbors.x == 1 || neighbors.z == 1;
  bool horizontal = neighbors.y == 2 || neighbors.w == 2;
  bvec4 opposite = equal(neighbors, ivec4(pattern == 3 ? 4 : 3));

  bool isTriangle = pattern >= 3;
  bool reject = any(bvec2(vertical && any(opposite.yw), horizontal && any(opposite.xz)));
  if (isTriangle && reject) {
    pattern = -pattern;
  }

  lowp vec4 result = vec4(0.0);
  result.x = float(pattern + 4) / 8.0;

#if SOFT_EDGES_SHARPENING
  lowp vec4 softEdges = vec4(
    softEdgeWeight(l04, l05, l06, l07),
    softEdgeWeight(l02, l06, l10, l14),
    softEdgeWeight(l08, l09, l10, l11),
    softEdgeWeight(l01, l05, l09, l13)
  );
  result.y = quickPackFloats2(softEdges.xy * 0.5 + vec2(0.5));
  result.z = quickPackFloats2(softEdges.zw * 0.5 + vec2(0.5));
#endif

  gl_FragColor = result;
}
