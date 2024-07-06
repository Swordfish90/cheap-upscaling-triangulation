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

import * as THREE from "three";

export function setUpDragging(
  window: Window,
  fetchPosition: () => THREE.Vector2,
  updatePosition: (position: THREE.Vector2) => void,
  fetchScale: () => number,
  updateScale: (scale: number) => void,
) {
  let imageScale = 1;
  let mouseStart = new THREE.Vector2();
  let imageStart = new THREE.Vector2();
  let isDragging = false;

  window.addEventListener('mousedown', (e) => {
    imageStart = fetchPosition();
    imageScale = fetchScale();
    mouseStart = new THREE.Vector2(e.pageX, e.pageY);
    isDragging = true;
  });

  window.addEventListener('mousemove', (e) => {
    if (isDragging) {
      const updatedPosition = new THREE.Vector2(
        imageStart.x - 2.0 * (e.pageX - mouseStart.x) / imageScale,
        imageStart.y + 2.0 * (e.pageY - mouseStart.y) / imageScale
      )

      updatePosition(updatedPosition)
    }
  });

  window.addEventListener('wheel', (e) => {
    let scale = fetchScale()
    const delta = e.deltaY > 0 ? 1.1 : 0.9;
    scale *= delta;
    updateScale(scale);
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  window.addEventListener('mouseleave', () => {
    isDragging = false;
  });
}
