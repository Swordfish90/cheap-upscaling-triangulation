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

const localStorageLeftShaderKey = "left-shader";
const localStorageRightShaderKey = "right-shader";
const shaderValues = ['Nearest', 'Linear', 'CUT1', 'CUT2', 'CUT3'];

const images = [
  'hqx-patterns.bmp',
  'mario-nes.png',
  'pokemon-yellow-sgb.png',
  'advance-wars-gba.png',
  'ffvii-psx.png',
  'medievil-resurrection-psp.png',
  'hk-3-720.png',
  'hk-4-720.png',
  'sr4-5-720.png',
  'sr4-3-720.png',
  'doom-0-720.png',
];

function initializeImageElement(image: string) {
  const imgElement = document.createElement('img');
  imgElement.src = image;
  imgElement.classList.add('grid-image');
  imgElement.addEventListener('click', () => {
    const params = new URLSearchParams();
    params.set('src', image);
    params.set('left', localStorage.getItem(localStorageLeftShaderKey) || shaderValues[0]);
    params.set('right', localStorage.getItem(localStorageRightShaderKey) || shaderValues[4]);

    window.location.href = `/cheap-upscaling-triangulation/demo.html?${params.toString()}`;
  });
  return imgElement;
}

function initializeSelectElement(selector: HTMLSelectElement, localStorageId: string, defaultValue: string) {
  shaderValues.forEach((shaderValue) => {
    const newOption = document.createElement('option');
    newOption.value = shaderValue;
    newOption.text = shaderValue;
    selector.appendChild(newOption);
  });
  selector.value = localStorage.getItem(localStorageId) || defaultValue;
  selector.addEventListener("change", () => {
    localStorage.setItem(localStorageId, selector.value);
  });
}

const gridContainer = document.getElementById("image-grid")!;
images.forEach((image) => {
  gridContainer.appendChild(initializeImageElement(image));
});

const leftShaderSelect= document.getElementById("left-shader-select") as HTMLSelectElement;
const rightShaderSelect= document.getElementById("right-shader-select") as HTMLSelectElement;

initializeSelectElement(leftShaderSelect, localStorageLeftShaderKey, shaderValues[0]);
initializeSelectElement(rightShaderSelect, localStorageRightShaderKey, shaderValues[4]);
