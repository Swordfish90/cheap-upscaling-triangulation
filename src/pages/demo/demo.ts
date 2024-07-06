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

import '../../styles/style.css';
import * as THREE from 'three';

import {LINEAR_SHADERS, NEAREST_SHADERS} from "../../shaders/default.ts";
import {loadFromImage} from "../../loaders.ts";
import {CUT1_SHADERS} from "../../shaders/cut1.ts";
import {CUT2_SHADERS} from "../../shaders/cut2.ts";
import {CUT3_SHADERS} from "../../shaders/cut3.ts";
import {Chain} from "../../chain.ts";

const params = new URLSearchParams(window.location.search);
const imageSrc: string = params.get('src') || "doom-0-720.png";
const leftAlgorithmName: string = params.get('left') || "nearest";
const rightAlgorithmName: string = params.get('right') || "cut3";

function parseAlgorithm(algorithmName: string): Chain {
  switch (algorithmName) {
    case "Nearest": return NEAREST_SHADERS;
    case "Linear": return LINEAR_SHADERS;
    case "CUT1": return CUT1_SHADERS;
    case "CUT2": return CUT2_SHADERS;
    case "CUT3": return CUT3_SHADERS;
  }
  return LINEAR_SHADERS
}

function appendCanvas(canvas: HTMLCanvasElement) {
  document.getElementById("app")?.appendChild(canvas);
}

loadFromImage(
  imageSrc,
  parseAlgorithm(leftAlgorithmName),
  new THREE.Vector2(0.50, 1.0),
).then((canvas) => {
    appendCanvas(canvas)
    loadFromImage(
      imageSrc,
      parseAlgorithm(rightAlgorithmName),
      new THREE.Vector2(0.50, 1.0),
    ).then((canvas) => appendCanvas(canvas))
  }
)
