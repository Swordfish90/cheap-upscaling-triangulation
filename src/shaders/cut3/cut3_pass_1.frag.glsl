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

precision lowp float;

#define EPSILON 0.02

const lowp float STEP = 0.5 / float(SEARCH_MAX_DISTANCE);
const lowp float HSTEP = (STEP * 0.5);

uniform lowp sampler2D previousPass;

varying HIGHP vec2 passCoords;
varying HIGHP vec2 c05;
varying HIGHP vec2 dc;

lowp float quickPackBools2(bvec2 values) {
  return dot(vec2(values), vec2(0.5, 0.25));
}

lowp float quickPackFloats2(lowp vec2 values) {
  return dot(floor(values * vec2(12.0) + vec2(0.5)), vec2(0.0625, 0.00390625));
}

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

lowp int fetchPattern(lowp float value) {
  return int(value * 8.0 + 0.5) - 4;
}

lowp vec2 walk(
  lowp sampler2D previousPass,
  HIGHP vec2 baseCoords,
  HIGHP vec2 direction,
  lowp vec2 results,
  lowp int continuePattern
) {
  lowp vec2 result = vec2(0.0, 0.0);
  for (lowp int i = 1; i <= SEARCH_MAX_DISTANCE; i++) {
    HIGHP vec2 coords = baseCoords + direction * float(i);
    lowp int currentPattern = fetchPattern(texture2D(previousPass, coords).x);

    if (currentPattern == 3) {
      result.y = results.x;
    } else if (currentPattern == 4) {
      result.y = results.y;
    }

    if (currentPattern == 3 || currentPattern == 4) {
      result.x += HSTEP;
    } else if (currentPattern == continuePattern) {
      result.x += STEP;
    }

    if (currentPattern != continuePattern) { break; }
  }
  return result;
}

lowp float blendWeights(lowp vec2 d1, lowp vec2 d2) {
  const float MAX_DOUBLE_DISTANCE = float(SEARCH_MAX_DISTANCE) * STEP;
  const float MAX_DISTANCE = STEP * float(SEARCH_MAX_DISTANCE / 2) + HSTEP;

  lowp float result = 0.0;

  lowp float totalDistance = d1.x + d2.x;
  lowp float d1Ratio = d1.x / totalDistance;

  if (totalDistance <= EPSILON) {
    result = 0.0;
  } else if (totalDistance <= MAX_DOUBLE_DISTANCE) {
    result = (d1.x < d2.x) ? mix(d1.y, 0.0, 2.0 * d1Ratio) : mix(0.0, d2.y, (d1Ratio - 0.5) * 2.0);
  } else if (d1.x <= MAX_DISTANCE) {
    result = mix(d1.y, 0.0, d1.x / MAX_DISTANCE);
  } else if (d2.x <= MAX_DISTANCE) {
    result = mix(d2.y, 0.0, d2.x / MAX_DISTANCE);
  }

  return result;
}

void main() {
  lowp vec4 previousPassPixel = texture2D(previousPass, passCoords);
  lowp int pattern = fetchPattern(previousPassPixel.x);

  lowp vec2 resultN = vec2(0.0, 0.0);
  lowp vec2 resultS = vec2(0.0, 0.0);
  lowp vec2 resultW = vec2(0.0, 0.0);
  lowp vec2 resultE = vec2(0.0, 0.0);

  if (pattern == 1 || pattern == 3 || pattern == 4) {
    resultN = walk(previousPass, passCoords, vec2(0.0, -dc.y), vec2(-1.0, +1.0), 1);
    resultS = walk(previousPass, passCoords, vec2(0.0, +dc.y), vec2(+1.0, -1.0), 1);
  }
  if (pattern == 2 || pattern == 3 || pattern == 4) {
    resultW = walk(previousPass, passCoords, vec2(-dc.x, 0.0), vec2(-1.0, +1.0), 2);
    resultE = walk(previousPass, passCoords, vec2(+dc.x, 0.0), vec2(+1.0, -1.0), 2);
  }
  lowp vec4 edgesWeights[4];

  if (pattern == 1) {
    edgesWeights[0] = vec4(resultN, resultS + vec2(STEP, 0.0));
    edgesWeights[2] = vec4(resultN + vec2(STEP, 0.0), resultS);
  } else if (pattern == 2) {
    edgesWeights[3] = vec4(resultW, resultE + vec2(STEP, 0.0));
    edgesWeights[1] = vec4(resultW + vec2(STEP, 0.0), resultE);
  } else if (pattern == 3) {
    edgesWeights[0] = vec4(resultN, vec2(HSTEP, 1.0));
    edgesWeights[2] = vec4(vec2(HSTEP, -1.0), resultS);
    edgesWeights[3] = vec4(resultW, vec2(HSTEP, 1.0));
    edgesWeights[1] = vec4(vec2(HSTEP, -1.0), resultE);
  } else if (pattern == 4) {
    edgesWeights[0] = vec4(resultN, vec2(HSTEP, -1.0));
    edgesWeights[2] = vec4(vec2(HSTEP, 1.0), resultS);
    edgesWeights[3] = vec4(resultW, vec2(HSTEP, -1.0));
    edgesWeights[1] = vec4(vec2(HSTEP, 1.0), resultE);
  }
  lowp vec4 edges = vec4(
    blendWeights(edgesWeights[0].xy, edgesWeights[0].zw),
    blendWeights(edgesWeights[1].xy, edgesWeights[1].zw),
    blendWeights(edgesWeights[2].xy, edgesWeights[2].zw),
    blendWeights(edgesWeights[3].xy, edgesWeights[3].zw)
  );

#if SOFT_EDGES_SHARPENING
  lowp vec4 softEdges = 2.0 * SOFT_EDGES_SHARPENING_AMOUNT * vec4(
    quickUnpackFloats2(previousPassPixel.y + 0.001953125) - vec2(0.5),
    quickUnpackFloats2(previousPassPixel.z + 0.001953125) - vec2(0.5)
  );

  edges = clamp(edges + softEdges, min(edges, softEdges), max(edges, softEdges));
#endif

  lowp int originalPattern = pattern >= 0 ? pattern : -pattern;
  if (originalPattern == 3) {
    edges = vec4(-edges.x, edges.w, -edges.z, edges.y);
  }

  gl_FragColor = vec4(
    quickPackBools2(bvec2(originalPattern >= 3, originalPattern == 3)),
    quickPackFloats2(edges.xy * 0.5 + vec2(0.5)),
    quickPackFloats2(edges.zw * 0.5 + vec2(0.5)),
    1.0
  );
}
