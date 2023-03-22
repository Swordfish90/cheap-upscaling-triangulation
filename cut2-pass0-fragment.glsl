#ifdef GL_FRAGMENT_PRECISION_HIGH
#define HIGHP highp
#else
#define HIGHP mediump
precision mediump float;
#endif

#define EPSILON 0.02

#define EDGE_USE_FAST_LUMA 0         // Use quick luma approximation in edge detection
#define EDGE_MIN_VALUE 0.05          // Minimum luma difference used in edge detection [0, 1]
#define EDGE_MIN_CONTRAST 1.20       // Minimum contrast ratio used in edge detection [1, ∞]
#define LUMA_ADJUST_GAMMA 0          // Correct gamma to better approximate luma human perception

uniform lowp sampler2D texture;

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

struct Pattern {
  lowp float type;
  bvec3 flip;
  bvec2 cuts;
};

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

lowp float maxOf(lowp float a, lowp float b, lowp float c, lowp float d) {
  return max(max(a, b), max(c, d));
}

lowp float minOf(lowp float a, lowp float b, lowp float c, lowp float d) {
  return min(min(a, b), min(c, d));
}

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

bool hasEdge(lowp float a, lowp float b, lowp float c, lowp float d) {
  lowp float diff1 = distance(a, d);
  lowp float diff2 = max(
    min(distance(a, b), distance(b, d)),
    min(distance(a, c), distance(c, d))
  );
  return max(EDGE_MIN_CONTRAST * diff1, EDGE_MIN_VALUE) < diff2;
}

lowp float pack(bool a, bool b, bool c) {
  return dot(vec3(float(a), float(b), float(c)), vec3(4.0, 16.0, 64.0)) / 255.0;
}

void main() {
  lowp vec3 t01 = texture2D(texture, c01).rgb;
  lowp vec3 t02 = texture2D(texture, c02).rgb;
  lowp vec3 t04 = texture2D(texture, c04).rgb;
  lowp vec3 t05 = texture2D(texture, c05).rgb;
  lowp vec3 t06 = texture2D(texture, c06).rgb;
  lowp vec3 t07 = texture2D(texture, c07).rgb;
  lowp vec3 t08 = texture2D(texture, c08).rgb;
  lowp vec3 t09 = texture2D(texture, c09).rgb;
  lowp vec3 t10 = texture2D(texture, c10).rgb;
  lowp vec3 t11 = texture2D(texture, c11).rgb;
  lowp vec3 t13 = texture2D(texture, c13).rgb;
  lowp vec3 t14 = texture2D(texture, c14).rgb;

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

  // Main diagonals
  bool d05_10 = hasEdge(l05, l06, l09, l10);
  bool d06_09 = hasEdge(l06, l05, l10, l09);

  // Saddle fix
  if (d05_10 && d06_09) {
    lowp float diff1 = distance(l06, l01) + distance(l11, l06) + distance(l09, l04) + distance(l14, l09);
    lowp float diff2 = distance(l05, l02) + distance(l08, l05) + distance(l10, l07) + distance(l13, l10);
    d05_10 = diff1 + EPSILON < diff2;
    d06_09 = diff2 + EPSILON < diff1;
  }

  // Vertical diagonals
  bvec2 d01_10 = hasEdge(l10, l09, l06, l05, l02, l01);
  bvec2 d02_09 = hasEdge(l09, l10, l05, l06, l01, l02);
  bvec2 d05_14 = hasEdge(l05, l06, l09, l10, l13, l14);
  bvec2 d06_13 = hasEdge(l06, l05, l10, l09, l14, l13);

  // Horizontal diagonals
  bvec2 d04_10 = hasEdge(l10, l06, l09, l05, l08, l04);
  bvec2 d06_08 = hasEdge(l06, l10, l05, l09, l04, l08);
  bvec2 d05_11 = hasEdge(l05, l09, l06, l10, l07, l11);
  bvec2 d07_09 = hasEdge(l09, l05, l10, l06, l11, l07);

  bvec4 type5 = bvec4(d02_09.x && d06_08.x, d01_10.x && d05_11.x, d06_13.x && d07_09.x, d05_14.x && d04_10.x);
  bvec4 type4 = bvec4(d05_11.x && d06_08.x, d04_10.x && d07_09.x, d05_14.x && d02_09.x, d01_10.x && d06_13.x);
  bvec4 type3 = bvec4(d05_11.x && d04_10.x, d06_08.x && d07_09.x, d01_10.x && d05_14.x, d02_09.x && d06_13.x);
  bvec4 type2_v = bvec4(d01_10.x, d02_09.x, d05_14.x, d06_13.x);
  bvec4 type2_h = bvec4(d04_10.x, d06_08.x, d05_11.x, d07_09.x);
  bvec2 type1 = bvec2(d05_10, d06_09);

  bool bottomCut = any(bvec4(all(d05_11), all(d07_09), all(d05_14), all(d06_13)));
  bool topCut = any(bvec4(all(d01_10), all(d02_09), all(d04_10), all(d06_08)));

  lowp vec4 final = vec4(0.0, 0.0, 0.0, 1.0);

  Pattern pattern;

  if (any(type5)) {
    pattern.type = 0.55;
    pattern.flip = bvec3(type5.z, type5.x, type5.y);
    pattern.cuts = bvec2(false, false);
  } else if (any(type4)) {
    pattern.type = 0.45;
    pattern.flip = bvec3(type4.w, type4.y, type4.x || type4.y);
    pattern.cuts = bvec2(bottomCut, topCut);
  } else if (any(type3)) {
    pattern.type = 0.35;
    pattern.flip = bvec3(type3.w, type3.y, type3.x || type3.y);
    pattern.cuts = bvec2(bottomCut, !topCut);
  } else if (any(type2_v)) {
    pattern.type = 0.25;
    pattern.flip = bvec3(type2_v.x || type2_v.w, type2_v.y || type2_v.x, false);
    pattern.cuts = bvec2(bottomCut || topCut, false);
  } else if (any(type2_h)) {
    pattern.type = 0.25;
    pattern.flip = bvec3(type2_h.y || type2_h.x, type2_h.w || type2_h.x, true);
    pattern.cuts = bvec2(bottomCut || topCut, false);
  } else if (any(type1)) {
    pattern.type = 0.15;
    pattern.flip = bvec3(type1.y, false, false);
    pattern.cuts = bvec2(false, false);
  }

  gl_FragColor = vec4(
    pattern.type,
    pack(pattern.flip.x, pattern.flip.y, pattern.flip.z),
    pack(pattern.cuts.x, pattern.cuts.y, false),
    1.0
  );
}
