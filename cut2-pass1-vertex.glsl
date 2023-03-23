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

varying HIGHP vec2 screenCoords;
varying HIGHP vec2 passCoords;
varying HIGHP vec2 c05;
varying HIGHP vec2 c06;
varying HIGHP vec2 c09;
varying HIGHP vec2 c10;

void main() {
  HIGHP vec2 coords = vec2(vCoordinate.x, mix(vCoordinate.y, 1.0 - vCoordinate.y, vFlipY)) * 1.0001;
  screenCoords = coords * textureSize - vec2(0.5);
  c05 = (screenCoords + vec2(+0.0, +0.0)) / textureSize;
  c06 = (screenCoords + vec2(+1.0, +0.0)) / textureSize;
  c09 = (screenCoords + vec2(+0.0, +1.0)) / textureSize;
  c10 = (screenCoords + vec2(+1.0, +1.0)) / textureSize;
  passCoords = vec2(c05.x, mix(c05.y, 1.0 - c05.y, vFlipY));
  gl_Position = vViewModel * vPosition;
}
