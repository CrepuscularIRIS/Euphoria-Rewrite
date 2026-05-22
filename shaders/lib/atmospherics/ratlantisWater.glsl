#ifndef LUX_WATER_GLSL
#define LUX_WATER_GLSL

// ---- Lux Shader water waves adapted for Euphoria-Rewrite --------------------
// Original by TechDevOnGithub (Lux Shader v1.2), based on BSL Shaders v7.1.05
// Replaces the earlier Photon/Gerstner approach (ratlantisWater) with Lux's
// sin-wave + layered noise stack which produces wider, more natural-looking
// ocean-style surface motion. Finite-difference normals for full parallax compat.
//
// Adaptations for EP:
//   Saturate(x)    → clamp01(x)      (EP convention)
//   Pow2(x)        → pow2(x)         (EP has pow2..pow4)
//   Hash11(x)      → local luxWaveHash11  (avoids name collision with EP hash11)
//   TAU constant   → local #define   (EP may not define it)
//   dist varying   → computed from cameraPosition uniform
//   normal varying → not needed (mult uses distance-only LOD)

#include "/lib/shaderSettings/ratlantisWater.glsl"

#ifndef TAU
#define TAU 6.28318530718
#endif

float luxWaveHash11(float x) {
    x = fract(x * 0.3183099);
    x += dot(x, x + 19.19);
    return fract(x * 0.3183099);
}

// Single Lux wave layer: sin(k*dot(dir, pos) - 3*speed*t + cos(...)) / k
float GetLuxWaveLayer(vec2 coord, float wavelength, vec2 dir, float speed) {
    float k = TAU / wavelength;
    float x = k * dot(normalize(dir), coord) - frameTimeCounter * 3.0 * speed;
    return sin(x + cos(x) * 0.8) / k;
}

// Multi-octave wave + noise stack (Lux ComputeWaterWaves, verbatim logic).
// planeCoord: worldPos.xz
// mult:       distance-based LOD weight [0, 1]
float ComputeLuxWaterWaves(vec2 planeCoord, float mult) {
    float noise    = 0.0;
    float waveLen  = LUX_WAVE_LENGTH;
    float waveAmp  = LUX_WAVE_AMPLITUDE;
    float noiseScl = LUX_NOISE_SCALE;
    float noiseAmp = LUX_NOISE_AMPLITUDE;

    for (int i = 0; i < LUX_WAVE_ITERATIONS; i++) {
        vec2 dir = vec2(luxWaveHash11(float(i)), luxWaveHash11(-float(i))) * 2.0 - 1.0;
        dir      = mix(vec2(1.0), dir, LUX_WAVE_DIR_SPREAD);
        noise   += GetLuxWaveLayer(planeCoord * 8.4, waveLen, dir, LUX_WAVE_SPEED) * waveAmp;
        waveLen *= LUX_WAVE_LACUNARITY;
        waveAmp *= LUX_WAVE_PERSISTENCE;
    }
    noise *= waveAmp; // final amplitude scale (matches Lux exactly)

    for (int i = 0; i < LUX_NOISE_ITERATIONS; i++) {
        // Alternate wind sign each octave for crossing surface ripples (Lux pattern)
        float sign = float(i % 2 == 0) * 2.0 - 1.0;
        float wind = frameTimeCounter * LUX_WAVE_SPEED * 0.7 * sign;
        noise += texture2DLod(noisetex, (planeCoord + wind) * noiseScl, 0.0).r * noiseAmp;
        noiseScl *= LUX_NOISE_LACUNARITY;
        noiseAmp *= LUX_NOISE_PERSISTENCE;
    }

    return noise * pow2(mult);
}

// Height at worldPos using distance-only LOD (skips Lux's view-angle term,
// which needs the `normal` and `dist` varyings not available at global scope).
float GetLuxWaterHeight(vec3 worldPos, float viewDist) {
    float mult = min(1.0 / pow(max(viewDist, 4.0), 0.25), 1.0);
    if (mult < 0.01) return 0.0;
    return ComputeLuxWaterWaves(worldPos.xz, mult);
}

// Finite-difference XZ slopes via 4-sample central difference (Lux GetWaterNormal pattern).
// worldPos: absolute world position of the water fragment (playerPos + cameraPosition).
// Central difference: (h+ - h-) / (2*step) — more accurate than one-sided.
vec2 GetLuxWaterSlopes(vec3 worldPos) {
    const float h  = 0.1;
    float viewDist = length(worldPos - cameraPosition);
    float h1 = GetLuxWaterHeight(worldPos + vec3( h, 0.0, 0.0), viewDist);
    float h2 = GetLuxWaterHeight(worldPos + vec3(-h, 0.0, 0.0), viewDist);
    float h3 = GetLuxWaterHeight(worldPos + vec3(0.0, 0.0,  h), viewDist);
    float h4 = GetLuxWaterHeight(worldPos + vec3(0.0, 0.0, -h), viewDist);
    return vec2(h1 - h2, h3 - h4) / (2.0 * h);
}

// Depth absorption (differential wavelength: red >> green >> blue → teal-blue).
// Preserved from prior Ratlantis implementation — same formula, same coefficients.
vec3 GetLuxWaterAbsorption(float depth, float murkiness) {
    float d = depth * murkiness;
    return vec3(exp(-d * 0.90), exp(-d * 0.52), exp(-d * 0.22));
}

#endif // LUX_WATER_GLSL
