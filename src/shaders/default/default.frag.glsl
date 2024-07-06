precision mediump float;

varying vec2 vUv; // Receiving UV coordinates from the vertex shader

uniform sampler2D tex0; // The texture sampler

void main() {
  vec4 color = texture2D(tex0, vUv); // Sample the texture using UV coordinates
  gl_FragColor = color;
}
