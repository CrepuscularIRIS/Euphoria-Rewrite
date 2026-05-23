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

check 'float noiseCoverage = abs\(attenuation - 0\.125\) \* \(attenuation > 0\.125 \? 1\.14 : 6\.0\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud coverage must match Solas'

check 'noiseCoverage \*= noiseCoverage \* 6\.0;' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud coverage shaping must match Solas'

check 'noise = max\(noise - END_DISK_AMOUNT - 1\.0 \+ epEndProtoplanetaryDisk\(rayPos\) \* 2\.0, 0\.0\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud central disk boost must match Solas'

check 'float powder = 1\.0 - 0\.925 \* exp\(-pow\(noise, 1\.0 \+ noise \* 7\.0\)\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud powder term must match Solas'

check 'float directionalScattering = 1\.0 - exp\(-2\.0 \* \(noise - lightingNoise \* 0\.9\)\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud directional scattering must match Solas'

check 'texture2DLod\(solasEndNoiseTex, rayPos \+ wind \* 0\.5, 0\.0\)\.g' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud base noise must use the Solas-specific noise texture'

check 'void computeEndDiskClouds\(inout vec4 vc, vec3 nWorldPos,' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk clouds should stay on the stable direction-based integration path'

check 'vec3 solasDiskLight = vec3\(0\.95, 1\.0, 0\.5\) \* \(diskLightSqrt \* diskLightSqrt\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud final light color must come from the Solas end-light chain'

check 'vec3 euphoriaDiskLight = endLightColor' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud lighting should be corrected through Euphoria''s live End light color'

check 'cloudColor \*= cloudLighting \* \(1\.35 \+ scattering \* 1\.2\);' \
  "$root/shaders/lib/atmospherics/endClouds.glsl" \
  'End disk cloud final lighting must preserve a bright Solas-like white disk under Euphoria tonemapping'

check 'return texture2DLod\(solasEndNoiseTex, coord, 0\.0\);' \
  "$root/shaders/lib/atmospherics/endNebula.glsl" \
  'End nebula and black hole must sample the Solas-specific noise texture'

check 'float VoSBH\s*=\s*clamp01\(VoS\);' \
  "$root/shaders/lib/atmospherics/endNebula.glsl" \
  'End black hole must clamp to the forward hemisphere to avoid a mirrored second core'

check 'texture2DLod\(solasEndNoiseTex, \(wpos\.xz / wpos\.y\) \* 0\.5 \+ frameTimeCounter \* 0\.004, 0\.0\)\.g' \
  "$root/shaders/program/deferred1.glsl" \
  'End smoke must use the Solas-specific noise texture'

check 'color\.rgb = mix\(color\.rgb, epEndClouds\.rgb, epEndClouds\.a\);' \
  "$root/shaders/program/deferred1.glsl" \
  'End disk clouds must stay on the stable deferred1 sky composition path'

echo "end-atmosphere migration checks passed"
