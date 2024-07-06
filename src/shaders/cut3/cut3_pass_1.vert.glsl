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

uniform HIGHP vec2 textureSize;

varying HIGHP vec2 passCoords;
varying HIGHP vec2 c05;
varying HIGHP vec2 dc;

void main() {
  HIGHP vec2 coords = uv * 1.00001;
  HIGHP vec2 screenCoords = coords * textureSize - vec2(0.5);
  c05 = (screenCoords + vec2(+0.0, +0.0)) / textureSize;
  passCoords = c05;
  dc = vec2(1.0) / textureSize;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
