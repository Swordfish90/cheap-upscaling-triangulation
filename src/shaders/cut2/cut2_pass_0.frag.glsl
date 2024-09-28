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

lowp float maxOf(lowp vec4 values) {
  return max(max(values.x, values.y), max(values.z, values.w));
}

lowp float minOf(lowp vec4 values) {
  return min(min(values.x, values.y), min(values.z, values.w));
}

lowp float luma(lowp vec3 v) {
#if EDGE_USE_FAST_LUMA
  lowp float result = v.g;
#else
  lowp float result = dot(v, vec3(0.299, 0.587, 0.114));
#endif
  return result;
}

lowp float quickPackBools2(bvec2 values) {
  return dot(vec2(values), vec2(0.5, 0.25));
}

lowp float quickPackFloats2(lowp vec2 values) {
  return dot(floor(values * vec2(12.0) + vec2(0.5)), vec2(0.0625, 0.00390625));
}

struct Quad {
  lowp vec4 scores;
};

Quad quad(lowp vec4 values) {
  lowp vec4 edges = values.xyzx - values.ywwz;

  Quad result;
  result.scores = vec4(
    abs(edges.x + edges.z),
    abs(edges.w + edges.y),
    max(abs(edges.x - edges.y), abs(edges.w - edges.z)),
    max(abs(edges.x + edges.w), abs(edges.y + edges.z))
  );
  return result;
}

lowp int computePattern(lowp vec4 scores, lowp vec4 neighborsScores) {
  bool isDiagonal = max(scores.z, scores.w) > max(scores.x, scores.y);

  scores += 0.25 * neighborsScores;

  lowp int result = 0;
  if (!isDiagonal) {
    if (scores.x > scores.y + EDGE_MIN_VALUE) {
      result = 1;
    } else if (scores.y > scores.x + EDGE_MIN_VALUE) {
      result = 2;
    }
  } else {
    if (scores.z > scores.w + EDGE_MIN_VALUE) {
      result = 3;
    } else if (scores.w > scores.z + EDGE_MIN_VALUE) {
      result = 4;
    }
  }

  return result;
}

lowp int findPattern(Quad quad) {
  return computePattern(quad.scores, vec4(0.0));
}

lowp int findPattern(Quad quads[5]) {
  lowp vec4 adjustments = vec4(0.0);
  adjustments += quads[1].scores;
  adjustments += quads[2].scores;
  adjustments += quads[3].scores;
  adjustments += quads[4].scores;
  return computePattern(quads[0].scores, adjustments);
}

lowp float softEdgeWeight(lowp float a, lowp float b, lowp float c, lowp float d) {
  lowp float result = 0.0;
  result += clamp((abs(b - c) / (abs(a - c) + EPSILON)), 0.0, 1.0);
  result -= clamp((abs(c - b) / (abs(b - d) + EPSILON)), 0.0, 1.0);
  return clamp(2.0 * result, -1.0, 1.0);
}

lowp float hardEdgeWeight(lowp int cp, lowp int np, lowp int vertical, lowp int positiveDiagonal, lowp int negativeDiagonal) {
  lowp float result = 0.0;
  if ((cp == vertical && np == positiveDiagonal) || (np == vertical && cp == negativeDiagonal)) {
    result = 0.5;
  } else if ((cp == vertical && np == negativeDiagonal) || (np == vertical && cp == positiveDiagonal)) {
    result = -0.5;
  }
  return result;
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

  Quad quads[5];
  quads[0] = quad(vec4(l05, l06, l09, l10));
  quads[1] = quad(vec4(l01, l02, l05, l06));
  quads[2] = quad(vec4(l06, l07, l10, l11));
  quads[3] = quad(vec4(l09, l10, l13, l14));
  quads[4] = quad(vec4(l04, l05, l08, l09));

  lowp int pattern = findPattern(quads[0]);

  lowp ivec4 neighbors = ivec4(findPattern(quads[1]), findPattern(quads[2]), findPattern(quads[3]), findPattern(quads[4]));

  lowp vec4 edges = vec4(
    hardEdgeWeight(pattern, neighbors.x, 1, 4, 3),
    hardEdgeWeight(pattern, neighbors.y, 2, 3, 4),
    hardEdgeWeight(pattern, neighbors.z, 1, 3, 4),
    hardEdgeWeight(pattern, neighbors.w, 2, 4, 3)
  );

#if SOFT_EDGES_SHARPENING
  lowp vec4 softEdges = SOFT_EDGES_SHARPENING_AMOUNT * vec4(
    softEdgeWeight(l04, l05, l06, l07),
    softEdgeWeight(l02, l06, l10, l14),
    softEdgeWeight(l08, l09, l10, l11),
    softEdgeWeight(l01, l05, l09, l13)
  );

  edges = clamp(edges + softEdges, min(edges, softEdges), max(edges, softEdges));
#endif

  pattern = findPattern(quads);
  pattern = pattern > 0 ? pattern : -pattern;

  if (pattern == 3) {
    edges = vec4(-edges.x, edges.w, -edges.z, edges.y);
  }

  lowp vec4 result = vec4(
    quickPackBools2(bvec2(pattern >= 3, pattern == 3)),
    quickPackFloats2(edges.xy * 0.5 + vec2(0.5)),
    quickPackFloats2(edges.zw * 0.5 + vec2(0.5)),
    1.0
  );

  gl_FragColor = result;
}
