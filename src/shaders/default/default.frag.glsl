precision mediump float;

varying vec2 vUv;

uniform sampler2D tex0;

void main() {
  vec4 color = texture2D(tex0, vUv);
  gl_FragColor = color;
}
