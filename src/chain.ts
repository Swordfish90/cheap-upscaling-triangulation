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
import {setUpDragging} from "./events.ts";
import {Shader} from "./shader.ts";
import {clamp} from "./mathutils.ts";

export class Chain {
  constructor(readonly linearFiltering: boolean, readonly shaders: Shader[]) {}
}

export function createSceneWithShaderChain(
  texture: THREE.Texture,
  textureSize: THREE.Vector2,
  chain: Chain,
  size: THREE.Vector2,
): THREE.WebGLRenderer {
  const scenes: THREE.Scene[] = []
  const cameras: THREE.OrthographicCamera[] = []
  const planes: THREE.Mesh<THREE.PlaneGeometry>[] = []
  const renderTargets: THREE.WebGLRenderTarget[] = []
  const renderer = new THREE.WebGLRenderer()

  console.log("Loading texture with size:", textureSize)

  texture.magFilter = chain.linearFiltering ? THREE.LinearFilter : THREE.NearestFilter
  texture.minFilter = chain.linearFiltering ? THREE.LinearFilter : THREE.NearestFilter

  const textureAspectRatio = textureSize.x / textureSize.y

  chain.shaders.forEach((shader, index) => {
    const scene = new THREE.Scene();
    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 10);
    camera.position.z = 2;

    const isLastShader = index === chain.shaders.length - 1;

    if (!isLastShader) {
      const renderTarget = new THREE.WebGLRenderTarget(
        textureSize.x,
        textureSize.y,
        {
          magFilter: THREE.NearestFilter,
          minFilter: THREE.NearestFilter,
          format: THREE.RGBAFormat,
        }
      );
      renderTargets.push(renderTarget);
    }

    const shaderMaterial = new THREE.ShaderMaterial({
      uniforms: {
        previousPass: {value: renderTargets[index - 1]?.texture},
        textureSize: {value: textureSize},
        tex0: {value: texture}
      },
      vertexShader: shader.vertexShader,
      fragmentShader: shader.fragmentShader
    });

    console.log(shaderMaterial)

    const geometry = new THREE.PlaneGeometry(2, 2);
    const plane = new THREE.Mesh(geometry, shaderMaterial);

    planes.push(plane)
    scene.add(plane);
    scenes.push(scene);
    cameras.push(camera);
  });

  function updateAspectRatio() {
    const rendererSize = new THREE.Vector2(window.innerWidth * size.width, window.innerHeight * size.height);
    const windowAspectRatio = rendererSize.width / rendererSize.height

    const plane = planes[planes.length - 1]
    plane.scale.set(1.0, 1.0 / (textureAspectRatio / windowAspectRatio), 1.0)

    renderer.setSize(rendererSize.x, rendererSize.y);
  }

  updateAspectRatio();

  window.addEventListener('resize', updateAspectRatio);

  function animate() {
    requestAnimationFrame(animate);

    chain.shaders.forEach((_, index) => {
      const isLastShader = index === chain.shaders.length - 1;
      renderer.setRenderTarget(isLastShader ? null : renderTargets[index]);
      renderer.render(scenes[index], cameras[index]);
    });
  }

  animate();

  setUpDragging(
    window,
    size,
    () => {
      const camera = cameras[cameras.length - 1];
      return new THREE.Vector2(camera.position.x * window.innerWidth, camera.position.y * window.innerHeight);
    },
    (position) => {
      const camera = cameras[cameras.length - 1];
      camera.position.x = clamp(position.x / window.innerWidth, -1, +1);
      camera.position.y = clamp(position.y / window.innerHeight, -1, +1);
    },
    () => {
      const camera = cameras[cameras.length - 1];
      return camera.zoom;
    },
    (scale) => {
      const camera = cameras[cameras.length - 1];
      camera.zoom = clamp(scale, 0.5, 16.0);
      camera.updateProjectionMatrix();
    },
  )

  return renderer
}
