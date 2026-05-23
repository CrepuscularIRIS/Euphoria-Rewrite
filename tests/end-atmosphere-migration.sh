#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if ! rg -q --multiline "$pattern" "$file"; then
    echo "FAIL: $message" >&2
    exit 1
  fi
}

check '^//#define END_VOID_VORTEX$' \
  "$root/shaders/lib/shaderSettings/endNebula.glsl" \
  'Bliss vortex must stay disabled in shader settings'

check '^#define END_NEBULA$' \
  "$root/shaders/lib/shaderSettings/endNebula.glsl" \
  'Solas end background must be enabled'

check '^uniform sampler2D solasEndNoiseTex;$' \
  "$root/shaders/lib/uniforms.glsl" \
  'A dedicated Solas end noise sampler must be declared'

check '^    customTexture\.solasEndNoiseTex=lib/textures/solas-end-noise\.png$' \
  "$root/shaders/shaders.properties" \
  'The Solas end noise texture must be bound without replacing Euphoria global noise'

check '"blur": true' \
  "$root/shaders/lib/textures/solas-end-noise.png.mcmeta" \
  'The Solas end noise texture must enable bilinear filtering to avoid nearest-neighbor block artifacts'

check '"clamp": false' \
  "$root/shaders/lib/textures/solas-end-noise.png.mcmeta" \
  'The Solas end noise texture must keep wrapping enabled for tiled cloud and nebula sampling'

check 'float noiseCoverage = abs\(attenuation - 0\.125\) \* \(attenuation > 0\.125 \? 1\.14 : 5\.0\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud coverage must match Solas'

check 'noiseCoverage \*= noiseCoverage \* 5\.0;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud coverage shaping must match Solas'

check 'return min\(spiral \* 1\.75, 1\.5\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud spiral shaping must match Solas'

check 'noise = max\(noise - END_DISK_AMOUNT - 1\.0 \+ epEndProtoplanetaryDisk\(rayPos\), 0\.0\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud central disk boost must match Solas'

check 'float sampleLighting = 0\.05 \+ clamp\(noise - lightingNoise \* \(0\.9 - scattering \* 0\.15\), 0\.0, 0\.95\) \* \(1\.5 \+ scattering\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud lighting response must match Solas'

check 'float nearSampleBoost = clamp01\(1\.0 - minDist / 384\.0\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk clouds must increase near-camera sample density to reduce close-range stepping artifacts'

check 'int sampleCount = int\(min\(planeDifference / rayLength, mix\(64\.0, 96\.0, nearSampleBoost\)\) \+ dither\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk clouds must raise the near-camera sample cap when the viewer approaches the cloud volume'

check 'texture2D\(solasEndNoiseTex, rayPos \+ wind \* 0\.5\)\.g' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud base noise must use the Solas-specific noise texture'

check 'void computeEndDiskClouds\(inout vec4 vc, vec3 viewPos, float z, float dither, inout float currentDepth\) \{' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk clouds must follow the Solas view-space integration path'

check 'vec3 diskLightSqrt = vec3\(END_BHOLE_LIGHT_R, END_BHOLE_LIGHT_G, END_BHOLE_LIGHT_B\) \* END_BHOLE_LIGHT_I;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud final light color must come from the Solas-aligned end light chain'

check 'vec3 endLightCol = diskLightSqrt \* diskLightSqrt;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud HDR light color must be rebuilt from the Solas-aligned sqrt-gamma values'

check 'vec3 cloudColor = vec3\(0\.95, 1\.0, 0\.5\) \* endLightCol;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud color tint must match Solas'

check 'cloudColor \*= cloudLighting \* 0\.35;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud final lighting scale must match Solas'

check 'return texture2DLod\(solasEndNoiseTex, coord, 0\.0\);' \
  "$root/shaders/lib/atmospherics/endNebula.glsl" \
  'End nebula and black hole must sample the Solas-specific noise texture'

check 'float VoSBH\s*=\s*clamp01\(VoS\);' \
  "$root/shaders/lib/atmospherics/endNebula.glsl" \
  'End black hole must clamp to the forward hemisphere to avoid a mirrored second core'

check 'texture2DLod\(solasEndNoiseTex, \(wpos\.xz / wpos\.y\) \* 0\.5 \+ frameTimeCounter \* 0\.004, 0\.0\)\.g' \
  "$root/shaders/program/deferred1.glsl" \
  'End smoke must use the Solas-specific noise texture'

check 'color\.rgb = epEndAmbientColSqrt \* 0\.175;' \
  "$root/shaders/program/deferred1.glsl" \
  'End sky base should come from the Solas ambient end color before adding nebula and disk clouds'

check 'vec3 epEndCloudColor = pow\(epEndClouds\.rgb, vec3\(1\.0 / 2\.2\)\);' \
  "$root/shaders/program/deferred1.glsl" \
  'End disk cloud color must be gamma-adjusted before sky composition to match Solas'

check 'vec3 endWorldDir = playerPos;' \
  "$root/shaders/program/deferred1.glsl" \
  'End nebula and black hole must be anchored from the Solas world-position path, not a pure view direction'

check 'color\.rgb = mix\(color\.rgb, epEndCloudColor, epEndClouds\.a\);' \
  "$root/shaders/program/deferred1.glsl" \
  'End disk clouds must stay on the stable deferred1 sky composition path'

echo "end-atmosphere migration checks passed"
