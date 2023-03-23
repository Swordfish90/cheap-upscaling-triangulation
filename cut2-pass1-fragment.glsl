#ifdef GL_FRAGMENT_PRECISION_HIGH
#define HIGHP highp
#else
#define HIGHP mediump
precision mediump float;
#endif

#define EPSILON 0.02

#define USE_DYNAMIC_BLEND 1          // Dynamically blend color with respect to contrast
#define BLEND_MIN_CONTRAST_EDGE 0.0  // Minimum contrast level at which sharpness starts increasing [0, 1]
#define BLEND_MAX_CONTRAST_EDGE 1.0  // Maximum contrast level at which sharpness stops increasing [0, 1]
#define BLEND_MIN_SHARPNESS 0.0      // Minimum sharpness level [0, 1]
#define BLEND_MAX_SHARPNESS 1.0      // Maximum sharpness level [0, 1]
#define STATIC_BLEND_SHARPNESS 0.5   // Sharpness level used when dynamic blending is disabled [0, 1]

precision mediump float;
uniform lowp sampler2D texture;
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

lowp float sharpSmooth(lowp float t, lowp float sharpness) {
  return linearStep(sharpness, 1.0 - sharpness, t);
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

lowp vec3 blend(lowp vec3 a, lowp vec3 b, lowp float t) {
  return mix(a, b, sharpSmooth(t, sharpness(luma(a), luma(b))));
}

lowp vec3 unpack(lowp float values) {
  return vec3(floor(mod(values / 4.0, 4.0)), floor(mod(values / 16.0, 4.0)), floor(mod(values / 64.0, 4.0)));
}

Pattern pattern0(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  return Pattern(pixels, false, pxCoords);
}

Pattern pattern1(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  Pattern result;
  if (pxCoords.y > pxCoords.x) {
    result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, pixels.p3);
    result.triangle = true;
    result.coords = vec2(pxCoords.x, pxCoords.y);
  } else {
    result.pixels = Pixels(pixels.p0, pixels.p1, pixels.p1, pixels.p3);
    result.triangle = true;
    result.coords = vec2(pxCoords.y, pxCoords.x);
  }
  return result;
}

Pattern pattern2(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  Pattern result;
  if (pxCoords.y > 2.0 * pxCoords.x) {
    result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, cd);
    result.triangle = true;
    result.coords = vec2(pxCoords.x * 2.0, pxCoords.y);
  } else {
    result.pixels = Pixels(pixels.p0, pixels.p1, cd, pixels.p3);
    result.triangle = false;
    result.coords = vec2((pxCoords.x - 0.5 * pxCoords.y) / (1.0 - 0.5 * pxCoords.y + EPSILON), pxCoords.y);
  }
  return result;
}

Pattern pattern3(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  Pattern result;
  if (pxCoords.y > 2.0 * pxCoords.x) {
    result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, cd);
    result.triangle = true;
    result.coords = vec2(pxCoords.x * 2.0, pxCoords.y);
  } else if (pxCoords.y < 2.0 * pxCoords.x - 1.0) {
    result.pixels = Pixels(pixels.p3, pixels.p1, pixels.p1, ab);
    result.triangle = true;
    result.coords = vec2((1.0 - pxCoords.x) * 2.0, 1.0 - pxCoords.y);
  } else {
    result.pixels = Pixels(pixels.p0, ab, cd, pixels.p3);
    result.triangle = false;
    result.coords = vec2(2.0 * (pxCoords.x - 0.5 * pxCoords.y), pxCoords.y);
  }
  return result;
}

Pattern pattern4(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  Pattern result;
  lowp float splitX = 0.5 * (1.0 - min(pxCoords.y, 1.0 - pxCoords.y));
  if (pxCoords.x < splitX) {
    result.pixels = Pixels(pixels.p0, ab, pixels.p2, cd);
    result.triangle = false;
    result.coords = vec2(pxCoords.x / splitX, pxCoords.y);
  } else {
    result.pixels = Pixels(ab, pixels.p1, cd, pixels.p3);
    result.triangle = false;
    result.coords = vec2((pxCoords.x - splitX) / (1.0 - splitX), pxCoords.y);
  }
  return result;
}

Pattern pattern5(Pixels pixels, lowp vec3 ab, lowp vec3 cd, lowp vec2 pxCoords) {
  Pattern result;
  if (pxCoords.y > pxCoords.x + 0.5) {
    result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, pixels.p3);
    result.triangle = true;
    result.coords = vec2(2.0 * pxCoords.x, 2.0 * (pxCoords.y - 0.5));
  } else if (pxCoords.y > pxCoords.x) {
    result.pixels = Pixels(pixels.p0, pixels.p0, pixels.p3, pixels.p3);
    result.triangle = true;
    result.coords = vec2(pxCoords.x, pxCoords.y);
  } else {
    result.pixels = Pixels(pixels.p0, pixels.p1, pixels.p1, pixels.p3);
    result.triangle = true;
    result.coords = vec2(pxCoords.y, pxCoords.x);
  }
  return result;
}

void main() {
  lowp vec3 t05 = texture2D(texture, c05).rgb;
  lowp vec3 t06 = texture2D(texture, c06).rgb;
  lowp vec3 t09 = texture2D(texture, c09).rgb;
  lowp vec3 t10 = texture2D(texture, c10).rgb;

  Pixels pixels = Pixels(t05, t06, t09, t10);

  lowp vec3 flagsTexture = texture2D(previousPass, passCoords).xyz;

  int patternType = int(flagsTexture.x * 10.0);
  lowp vec3 transform = unpack(floor(flagsTexture.y * 255.0 + 0.5));
  lowp vec3 patternFlags = unpack(floor(flagsTexture.z * 255.0 + 0.5));

  lowp vec2 pxCoords = fract(screenCoords);

  if (transform.x > 0.5) {
    pixels = Pixels(pixels.p1, pixels.p0, pixels.p3, pixels.p2);
    pxCoords.x = 1.0 - pxCoords.x;
  }

  if (transform.y > 0.5) {
    pixels = Pixels(pixels.p2, pixels.p3, pixels.p0, pixels.p1);
    pxCoords.y = 1.0 - pxCoords.y;
  }

  if (transform.z > 0.5) {
    pixels = Pixels(pixels.p0, pixels.p2, pixels.p1, pixels.p3);
    pxCoords = pxCoords.yx;
  }

  lowp vec3 ab = patternFlags.y > 0.5 ? pixels.p0 : pixels.p1;
  lowp vec3 cd = patternFlags.x > 0.5 ? pixels.p2 : pixels.p3;

  Pattern pattern;

  if (patternType == 0) {
    pattern = pattern0(pixels, ab, cd, pxCoords);
  } else if (patternType == 1) {
    pattern = pattern1(pixels, ab, cd, pxCoords);
  } else if (patternType == 2) {
    pattern = pattern2(pixels, ab, cd, pxCoords);
  } else if (patternType == 3) {
    pattern = pattern3(pixels, ab, cd, pxCoords);
  } else if (patternType == 4) {
    pattern = pattern4(pixels, ab, cd, pxCoords);
  } else {
    pattern = pattern5(pixels, ab, cd, pxCoords);
  }

  lowp vec3 weights = pattern.triangle ? triangle(pattern.coords) : quad(pattern.coords);

  lowp vec3 final = blend(
    blend(pattern.pixels.p0, pattern.pixels.p1, weights.x),
    blend(pattern.pixels.p2, pattern.pixels.p3, weights.y),
    weights.z
  );

  gl_FragColor = vec4(final, 1.0);
}
