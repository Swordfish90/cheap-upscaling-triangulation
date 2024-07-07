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
  let isPanning = false;
  let pinchDistance = 0;

  const handlePanStart = (pageX: number, pageY: number) => {
    imageStart = fetchPosition();
    imageScale = fetchScale();
    mouseStart = new THREE.Vector2(pageX, pageY);
    isPanning = true;
  };

  const handlePanMove = (pageX: number, pageY: number) => {
    if (isPanning) {
      const updatedPosition = new THREE.Vector2(
        imageStart.x - 2.0 * (pageX - mouseStart.x) / imageScale,
        imageStart.y + 2.0 * (pageY - mouseStart.y) / imageScale
      );

      updatePosition(updatedPosition);
    }
  };

  const handlePinchStart = (e: TouchEvent) => {
    pinchDistance = computePinchDistance(e.touches);
    imageScale = fetchScale();
  }

  const handlePinchMove = (e: TouchEvent) => {
    const newDistance = computePinchDistance(e.touches);
    const scaleChange = newDistance / pinchDistance;
    updateScale(imageScale * scaleChange);
  }

  window.addEventListener('mousedown', (e) => {
    handlePanStart(e.pageX, e.pageY);
  });

  window.addEventListener('mousemove', (e) => {
    handlePanMove(e.pageX, e.pageY);
  });

  window.addEventListener('wheel', (e) => {
    let scale = fetchScale();
    const delta = e.deltaY > 0 ? 1.1 : 0.9;
    scale *= delta;
    updateScale(scale);
  });

  window.addEventListener('mouseup', () => {
    isPanning = false;
  });

  window.addEventListener('mouseleave', () => {
    isPanning = false;
  });

  window.addEventListener(
    'touchstart',
    (e) => {
      e.preventDefault();
      if (e.touches.length === 1) {
        const touch = e.touches[0];
        handlePanStart(touch.pageX, touch.pageY);
      } else if (e.touches.length === 2) {
        isPanning = false;
        handlePinchStart(e);
      }
    },
    { passive: false }
  );

  window.addEventListener(
    'touchmove',
    (e) => {
      e.preventDefault();
      if (e.touches.length === 1) {
        const touch = e.touches[0];
        handlePanMove(touch.pageX, touch.pageY);
      } else if (e.touches.length === 2) {
        handlePinchMove(e);
      }
    },
    { passive: false }
  );

  window.addEventListener(
    'touchend',
    (e) => {
      e.preventDefault();
      if (e.touches.length < 1) {
        isPanning = false;
      }
    },
    { passive: false }
  );

  window.addEventListener('touchcancel', (e) => {
    e.preventDefault();
    isPanning = false;
  });
}

function computePinchDistance(touches: TouchList): number {
  const [touch1, touch2] = touches;
  const dx = touch2.pageX - touch1.pageX;
  const dy = touch2.pageY - touch1.pageY;
  return Math.sqrt(dx * dx + dy * dy);
}
