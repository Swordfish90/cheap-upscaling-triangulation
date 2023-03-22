#ifdef GL_FRAGMENT_PRECISION_HIGH
#define HIGHP highp
#else
#define HIGHP mediump
precision mediump float;
#endif

attribute vec4 vPosition;
attribute vec2 vCoordinate;
uniform lowp sampler2D texture;
uniform mat4 vViewModel;
uniform HIGHP vec2 textureSize;
uniform mediump float vFlipY;

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

void main() {
  HIGHP vec2 coords = vec2(vCoordinate.x, mix(vCoordinate.y, 1.0 - vCoordinate.y, vFlipY)) * 1.0001;
  HIGHP vec2 screenCoords = coords * textureSize - vec2(0.5);
  c01 = (screenCoords + vec2(+0.0, -1.0)) / textureSize;
  c02 = (screenCoords + vec2(+1.0, -1.0)) / textureSize;
  c04 = (screenCoords + vec2(-1.0, +0.0)) / textureSize;
  c05 = (screenCoords + vec2(+0.0, +0.0)) / textureSize;
  c06 = (screenCoords + vec2(+1.0, +0.0)) / textureSize;
  c07 = (screenCoords + vec2(+2.0, +0.0)) / textureSize;
  c08 = (screenCoords + vec2(-1.0, +1.0)) / textureSize;
  c09 = (screenCoords + vec2(+0.0, +1.0)) / textureSize;
  c10 = (screenCoords + vec2(+1.0, +1.0)) / textureSize;
  c11 = (screenCoords + vec2(+2.0, +1.0)) / textureSize;
  c13 = (screenCoords + vec2(+0.0, +2.0)) / textureSize;
  c14 = (screenCoords + vec2(+1.0, +2.0)) / textureSize;
  gl_Position = vPosition;
}
