#ifndef END_VORTEX_GLSL
#define END_VORTEX_GLSL

// ---- End Void Vortex -------------------------------------------------------
// Ported from Bliss v2.1.2 (Chocapic13 edit) shaders/lib/end_fog.glsl
// Hash: David Hoskins MIT  https://www.shadertoy.com/view/4djSRW
//
// Parameter alignment notes (Bliss → EP):
//   dL = 256        → worldDir * 256.0   (Bliss LUT calls GetVolumetricFog with viewVector*256)
//   SAMPLECOUNT 16  → VORTEX_STEPS define (compile-time; default 16 matches Bliss)
//   LUT colortex4   → time-based hash11  (no persistent buffer)
//   ManualLightPos  → removed (THE_ORB not ported)

#include "/lib/shaderSettings/endNebula.glsl"

// ---- hash31 (Bliss hash31) -------------------------------------------------
vec3 vp_hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

// ---- 3D noise (Bliss densityAtPosFog) --------------------------------------
float vpDensityAtPos(vec3 pos) {
    pos /= 18.0;
    pos.xz *= 0.5;
    vec3 p = floor(pos);
    vec3 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv    = p.xz + f.xz + p.y * vec2(0.0, 193.0);
    vec2 coord = uv / 512.0;
    vec2 xy    = texture2DLod(noisetex, coord, 0.0).yx;
    return mix(xy.r, xy.g, f.y);
}

// ---- Swirl (Bliss SwirlAroundOrigin) ---------------------------------------
void vpSwirlAroundOrigin(inout vec3 alteredOrigin, vec3 origin) {
    float radiance = 2.39996 + alteredOrigin.y / 1.5 + frameTimeCounter / 50.0;
    float s = sin(radiance), c = cos(radiance);
    mat2  rot = mat2(c, -s, s, c);
    float swirlBounds = clamp(
        sqrt(length(vec3(origin.x, origin.y - 100.0, origin.z)) / 200.0 - 1.0),
        0.0, 1.0);
    alteredOrigin.xz = mix(alteredOrigin.xz * rot, alteredOrigin.xz, swirlBounds);
}

// ---- Volume bounds (Bliss VolumeBounds) ------------------------------------
void vpVolumeBounds(inout float volume, vec3 origin) {
    vec3  o2    = origin - vec3(0.0, 100.0, 0.0);
    o2.y       *= 0.8;
    float bounds = max(1.0 - length(o2) / 75.0, 0.0) * 5.0;

    const float radius    = 150.0;
    const float thickness = 50.0 * radius;
    float torus = (thickness
                   - clamp(pow(length(vec2(length(origin.xz) - radius, o2.y)), 2.0)
                            - radius, 0.0, thickness))
                  / thickness;

    o2.xz *= 0.5;
    o2.y  -= 100.0;
    // orb term computed but unused (THE_ORB not ported)

    volume = max(volume - bounds - torus, 0.0);
}

// ---- Fog shape (Bliss fogShape) --------------------------------------------
float vpFogShape(vec3 pos) {
    float vortexBounds = clamp(300.0 - length(pos), 0.0, 1.0);
    vec3  samplePos    = pos * vec3(1.0, 1.0 / 48.0, 1.0);

    float voidZone = max(exp2(-1.0 * sqrt(max(pos.y - (-60.0), 0.0))), 0.0);

    vpSwirlAroundOrigin(samplePos, pos);

    float noise   = vpDensityAtPos(samplePos * 12.0);
    float erosion = 1.0 - vpDensityAtPos(
                        (samplePos - frameTimeCounter / 20.0) * (124.0 + (1.0 - noise) * 7.0));

    float clumpyFog = max(
        exp(noise * -mix(10.0, 4.0, vortexBounds)) * mix(2.0, 1.0, vortexBounds)
        - erosion * 0.3,
        0.0);

    vpVolumeBounds(clumpyFog, pos);
    return clumpyFog + voidZone;
}

// ---- Phase function (Bliss endFogPhase, peak reduced 5x for no-TAA stability) -
float vpEndFogPhase(vec3 lightPos) {
    float m = exp(length(lightPos) / -150.0);
    m *= m; m *= m;
    return m * 20.0;
}

// ---- Lightning flash (Bliss timer, approximated via hash; no colortex4 LUT) -
// Bliss stores flash in colortex4 with TAA blend: peak ~0.067, exp decay,
// half-life ~0.17s. Without a buffer we model the decay analytically.
// Peak is rescaled to ~0.3 because our phase function is 5x smaller than
// Bliss (peak 20 vs 100), so we need the lightning to be brighter at source
// to land at a comparable effective brightness after the phase multiplier.
float vpLightningFlash() {
    const float bucketSec = 1.5;  // average flash interval (~Bliss-like cadence)
    float bucket    = floor(frameTimeCounter / bucketSec);
    float timeSince = fract(frameTimeCounter / bucketSec) * bucketSec; // 0..bucketSec
    float trigger   = step(0.4, hash11(bucket));      // ~60% of buckets fire
    float decay     = exp(-timeSince * 3.5);          // half-life ~0.2s
    return 0.3 * trigger * decay;
}

// ---- Light source position (Bliss LightSourcePosition) ---------------------
// vortexBounds = 1 inside vortex → vortex-center light (Y=200 above island).
// vortexBounds = 0 outside → random lightning position (hash-based, no LUT).
vec3 vpLightSourcePosition(vec3 worldPos, float vortexBounds) {
    // Vortex center light at Y = 200 above End island origin
    vec3 vortexPos = worldPos - vec3(0.0, 200.0, 0.0);

    // Lightning position: snap to cell + random offset (approximates Bliss colortex4 walk)
    const float cellSize = 200.0;
    float seed       = floor(frameTimeCounter / 8.0);
    vec3  randOff    = (vp_hash31(seed) * 2.0 - 1.0) * 2.5;
    vec3  lightningPos = worldPos - cameraPosition;
    lightningPos += fract(cameraPosition / cellSize) * cellSize - cellSize * 0.5;
    lightningPos -= randOff;

    return mix(lightningPos, vortexPos, vortexBounds);
}

// ---- Light source colors (Bliss LightSourceColors) -------------------------
vec3 vpLightSourceColors(float vortexBounds, float lightningFlash, vec3 vortexColor) {
#ifdef END_LIGHTNING
    vec3 lightningColor = vec3(END_LIGHTNING_R, END_LIGHTNING_G, END_LIGHTNING_B)
                         * lightningFlash;
    return mix(lightningColor, vortexColor, vortexBounds);
#else
    return vortexColor;
#endif
}

// ---- Self-shadowed vortex lighting (Bliss LightSourceLighting) -------------
vec3 vpLightSourceLighting(vec3 startPos, vec3 lightPos, float noise,
                           float density, vec3 lightColor) {
    float phase  = vpEndFogPhase(lightPos);
    float shadow = 0.0;
    for (int j = 0; j < 3; j++) {
        vec3 sp = startPos - lightPos * (0.05 + float(j) * (0.25 + noise * 0.15));
        shadow += vpFogShape(sp);
    }
    vec3 direct = lightColor * phase * exp(shadow * -10.0);
    vec3 bloom  = lightColor * phase * phase
                * (1.0 - exp(shadow * shadow * shadow * vec3(-0.6, -2.0, -2.0)))
                * (1.0 - exp(-density * density));
    return direct + bloom;
}

// ---- Main raymarch (Bliss GetVolumetricFog) --------------------------------
// worldDir : normalize(mat3(gbufferModelViewInverse) * nViewPos)
// dL = 256 : matches Bliss LUT call site (viewVector * 256)
// Returns vec4(rgb, absorbance). Apply: color.rgb = color.rgb * r.a + r.rgb
//
// Dither note: Bliss uses temporal-only dither, but blends results into a
// 256x256 LUT with TAA (mixhistory ~ 0.067) which smooths frame-to-frame
// variation. EP has no LUT/TAA — using temporal-only dither here causes
// whole-screen flicker every frame. Per-pixel spatial dither is used instead;
// the trade-off is some high-frequency grain, which is far less disturbing
// than a synchronous screen-wide pulse.
vec4 GetEndVortex(vec3 worldDir, float dither) {
    // Bliss computes dL = length(cartToSphere(p) * 256), where cartToSphere
    // returns a NON-unit vector (length 0.87..1.0 depending on latitude).
    // So Bliss's dL varies per LUT pixel from ~222.9 to 256.
    // EP passes a normalized worldDir → dL is always 256. This produces ~13%
    // deeper integration on average vs Bliss but is architecturally unavoidable
    // without changing EP's sky parameterization. The visual impact is a
    // marginally denser fog; not flicker or color shift.
    const float dL        = 256.0;
    const float expFactor = 11.0;

    vec3  dVWorld      = worldDir * dL;
    vec3  vortexLightCol = vec3(VORTEX_LIGHT_R, VORTEX_LIGHT_G, VORTEX_LIGHT_B);
    float skyPhase       = 0.5
                         + pow(clamp(worldDir.y * 0.5 + 0.5, 0.0, 1.0), 4.0) * 5.0;

#ifdef END_LIGHTNING
    float lightningFlash = vpLightningFlash();
#else
    float lightningFlash = 0.0;
#endif

    vec3  color      = vec3(0.0);
    float absorbance = 1.0;

    for (int i = 0; i < VORTEX_STEPS; i++) {
        float fi  = float(i);
        float fN  = float(VORTEX_STEPS);
        float d   = (pow(expFactor, (fi + dither) / fN) / expFactor
                     - 1.0 / expFactor) / (1.0 - 1.0 / expFactor);
        float dd  = pow(expFactor, (fi + dither) / fN) * log(expFactor) / fN
                    / (expFactor - 1.0);

        vec3 progressW = cameraPosition + d * dVWorld;

        // vortexBounds: 1 inside vortex, 0 in outer storm zone
#ifdef END_LIGHTNING
        float vortexBounds = clamp(300.0 - length(progressW), 0.0, 1.0);
#else
        float vortexBounds = 1.0;
#endif

        vec3 lightPosition = vpLightSourcePosition(progressW, vortexBounds);
        vec3 lightColors   = vpLightSourceColors(vortexBounds, lightningFlash, vortexLightCol);

        float volumeDensity = vpFogShape(progressW);

        float clearArea   = 1.0 - min(max(1.0 - length(progressW - cameraPosition) / 100.0,
                                          0.0), 1.0);
        float stormDensity = min(volumeDensity, clearArea * clearArea * END_VORTEX_DENSITY);

        float volumeCoeff  = exp(-stormDensity * dd * dL);

        vec3 lightsources = vpLightSourceLighting(progressW, lightPosition,
                                                   dither, volumeDensity, lightColors);
        // Indirect ambient — Bliss hardcodes vec3(0.5, 0.75, 1.0), not vortexLightCol
        vec3 indirect     = vec3(0.5, 0.75, 1.0) * 0.2
                           * (exp(volumeDensity * volumeDensity * -50.0) * 0.9 + 0.1);
        vec3 stormLighting = indirect + lightsources;

        color      += (stormLighting - stormLighting * volumeCoeff) * absorbance;
        absorbance *= volumeCoeff;

        // Haze — does not affect absorbance (Bliss: separate accumulation)
        float hazeDensity  = 0.001 * END_HAZE_DENSITY;
        vec3  hazeLighting = vec3(0.3, 0.6, 1.0) * skyPhase;
        color += (hazeLighting - hazeLighting * exp(-hazeDensity * dd * dL)) * absorbance;
    }

    return vec4(color, absorbance);
}

#endif // END_VORTEX_GLSL
