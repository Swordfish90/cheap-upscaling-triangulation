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

import defaultVertexShader from './default/default.vert.glsl?raw';
import defaultFragmentShader from './default/default.frag.glsl?raw';
import {Chain} from "../chain.ts";

export const LINEAR_SHADERS = new Chain(
  true,
  [new Shader(defaultVertexShader, defaultFragmentShader)]
)

export const NEAREST_SHADERS = new Chain(
  false,
  [new Shader(defaultVertexShader, defaultFragmentShader)]
)
