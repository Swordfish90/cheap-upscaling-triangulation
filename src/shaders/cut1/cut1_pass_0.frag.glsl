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
precision mediump float;
#endif
#define EPSILON 0.02

precision mediump float;
uniform lowp sampler2D tex0;

varying HIGHP vec2 screenCoords;
varying HIGHP vec2 c05;
varying HIGHP vec2 c06;
varying HIGHP vec2 c09;
varying HIGHP vec2 c10;

lowp float luma(lowp vec3 v) {
#if EDGE_USE_FAST_LUMA
  lowp float result = v.g;
#else
  lowp float result = dot(v, vec3(0.299, 0.587, 0.114));
#endif
  return result;
}

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

lowp vec3 triangle(lowp vec2 pxCoords) {
  lowp vec3 ws = vec3(0.0);
  ws.x = pxCoords.y - pxCoords.x;
  ws.y = 1.0 - ws.x;
  ws.z = (pxCoords.y - ws.x) / (ws.y + EPSILON);
  return ws;
}

lowp vec3 quad(lowp vec2 pxCoords) {
  return vec3(pxCoords.x, pxCoords.x, pxCoords.y);
}

lowp float linearStep(lowp float edge0, lowp float edge1, lowp float t) {
  return clamp((t - edge0) / (edge1 - edge0 + EPSILON), 0.0, 1.0);
}

lowp float sharpness(lowp float l1, lowp float l2) {
  #if USE_DYNAMIC_BLEND
  lowp float lumaDiff = abs(l1 - l2);
  lowp float contrast = linearStep(BLEND_MIN_CONTRAST_EDGE, BLEND_MAX_CONTRAST_EDGE, lumaDiff);
  lowp float result = mix(BLEND_MIN_SHARPNESS * 0.5, BLEND_MAX_SHARPNESS * 0.5, contrast);
  #else
  lowp float result = STATIC_BLEND_SHARPNESS * 0.5;
  #endif
  return result;
}

bool hasDiagonal(lowp float a, lowp float b, lowp float c, lowp float d) {
  return distance(a, d) * 2.0 + EDGE_MIN_VALUE < distance(b, c);
}

lowp vec3 blend(lowp vec3 a, lowp vec3 b, lowp float t) {
  lowp float sharpness = sharpness(luma(a), luma(b));
  return mix(a, b, linearStep(sharpness, 1.0 - sharpness, t));
}

Pattern pattern0(Pixels pixels, lowp vec2 pxCoords) {
  return Pattern(pixels, false, pxCoords);
}

Pattern pattern1(Pixels pixels, lowp vec2 pxCoords) {
  Pattern result;
  if (pxCoords.y > pxCoords.x) {
    result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, pixels.p3);
    result.coords = vec2(pxCoords.x, pxCoords.y);
  } else {
    result.pixels = Pixels(pixels.p0, pixels.p1, pixels.p1, pixels.p3);
    result.coords = vec2(pxCoords.y, pxCoords.x);
  }
  result.triangle = true;
  return result;
}

void main() {
  lowp vec3 t05 = texture2D(tex0, c05).rgb;
  lowp vec3 t06 = texture2D(tex0, c06).rgb;
  lowp vec3 t09 = texture2D(tex0, c09).rgb;
  lowp vec3 t10 = texture2D(tex0, c10).rgb;

  lowp float l05 = luma(t05);
  lowp float l06 = luma(t06);
  lowp float l09 = luma(t09);
  lowp float l10 = luma(t10);

  Pixels pixels = Pixels(t05, t06, t09, t10);

  bool d05_10 = hasDiagonal(l05, l06, l09, l10);
  bool d06_09 = hasDiagonal(l06, l05, l10, l09);

  lowp vec2 pxCoords = fract(screenCoords);

  if (d06_09) {
    pixels = Pixels(pixels.p1, pixels.p0, pixels.p3, pixels.p2);
    pxCoords.x = 1.0 - pxCoords.x;
  }

  Pattern pattern;

  if (d05_10 || d06_09) {
    pattern = pattern1(pixels, pxCoords);
  } else {
    pattern = pattern0(pixels, pxCoords);
  }

  lowp vec3 weights = pattern.triangle ? triangle(pattern.coords) : quad(pattern.coords);

  lowp vec3 final = blend(
    blend(pattern.pixels.p0, pattern.pixels.p1, weights.x),
    blend(pattern.pixels.p2, pattern.pixels.p3, weights.y),
    weights.z
  );

  gl_FragColor = vec4(final, 1.0);
}
