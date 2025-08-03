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

import {Shader} from "../shader.ts";
import {Chain} from "../chain.ts";

import cut2Pass0VertexShader from './cut2/cut2_pass_0.vert.glsl?raw';
import cut2Pass0FragmentShader from './cut2/cut2_pass_0.frag.glsl?raw';
import cut2Pass1VertexShader from './cut2/cut2_pass_1.vert.glsl?raw';
import cut2Pass1FragmentShader from './cut2/cut2_pass_1.frag.glsl?raw';

const CUT2_DEFINES = `
  #define USE_DYNAMIC_BLEND               1
  #define BLEND_MIN_CONTRAST_EDGE         0.00
  #define BLEND_MAX_CONTRAST_EDGE         0.25
  #define BLEND_MIN_SHARPNESS             0.0
  #define BLEND_MAX_SHARPNESS             0.75
  #define STATIC_BLEND_SHARPNESS          0.50
  #define EDGE_USE_FAST_LUMA              0
  #define HARD_EDGES_SEARCH_MAX_ERROR     0.25
  #define SOFT_EDGES_SHARPENING           1
  #define SOFT_EDGES_SHARPENING_AMOUNT    1.00
  #define SOFT_EDGES_SHARPENING_USE_LUMA  0
`

export const CUT2_SHADERS = new Chain(
  false,
  [
    new Shader(CUT2_DEFINES + cut2Pass0VertexShader, CUT2_DEFINES + cut2Pass0FragmentShader),
    new Shader(CUT2_DEFINES + cut2Pass1VertexShader, CUT2_DEFINES + cut2Pass1FragmentShader),
  ]
)
