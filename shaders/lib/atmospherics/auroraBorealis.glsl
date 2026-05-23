#if !defined AURORA_BOREALIS_GLSL
#define AURORA_BOREALIS_GLSL
#ifdef ATM_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#include "/lib/util/colorConversion.glsl"

// ---- Dimension Preset (wrapper override for modded dimensions) ---------------
// 0 = Overworld (default EP aurora)
// 1 = Twilight Forest (LUX Shader v1.2 aurora, always-on)
// 2 = Ratlantis (Solas V3.3 aurora, always-on)
// Dedicated shader worlds inject 1/2 automatically; this stays available as a
// manual debug override.
#ifndef DIMENSION_PRESET
    #define DIMENSION_PRESET 0 //[0 1 2]
#endif
#if DIMENSION_PRESET == 1
    #define DIMENSION_TF
#elif DIMENSION_PRESET == 2
    #define DIMENSION_RATLANTIS
#endif

#define AURORA_CONDITION 3 //[-1 0 1 2 3 4]

#define AURORA_COLOR_PRESET 0 //[-1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14] // 0 is manual and default, 1 is daily, 2 is monthly and 3 is one color preset same with all numbers after.

#define AURORA_UP_R 112 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_UP_G 36 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_UP_B 192 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_UP_I 33 //[0 3 5 8 10 13 15 18 20 23 25 28 30 33 35 38 40 43 45 48 50 53 55 58 60 63 65 68 70 73 75 78 80 83 85 88 90 93 95 98 100]

#define AURORA_DOWN_R 96 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_DOWN_G 255 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_DOWN_B 192 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
#define AURORA_DOWN_I 33 //[0 3 5 8 10 13 15 18 20 23 25 28 30 33 35 38 40 43 45 48 50 53 55 58 60 63 65 68 70 73 75 78 80 83 85 88 90 93 95 98 100]

#define AURORA_SIZE 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]
#define AURORA_DRAW_DISTANCE 0.65 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define RANDOM_AURORA 0 //[0 1 2 3 4 5 6 7 8 9]

//#define RGB_AURORA

#define AURORA_CLOUD_INFLUENCE_INTENSITY 1.00 //[0.00 0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00]
#define AURORA_TERRAIN_INFLUENCE_INTENSITY 1.00 //[0.00 0.25 0.50 0.75 1.00 1.25 1.50]

#define AURORA_NOISE_SCALE 1.00 //[0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00 4.05 4.10 4.15 4.20 4.25 4.30 4.35 4.40 4.45 4.50 2.55 4.60 4.65 4.70 4.75 4.80 4.85 4.90 4.95 5.00]
#define AURORA_PATTERN_WARP 0 //[0 1 2 3 4 5 6 7 8 9 10]
#define AURORA_SATURATION 10 //[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
#define AURORA_COLOR_MIX_POWER 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

// TF sky atmospheric haze (additive horizon glow, blue-purple)
#define TF_SKY_HAZE_R 0.25 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define TF_SKY_HAZE_G 0.20 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define TF_SKY_HAZE_B 0.70 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define TF_SKY_HAZE_I 0.60 //[0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 1.00 1.20 1.50]

// ============================================================
// ---- Lux Shader v1.2 aurora helpers (Twilight Forest) ------
// Always-on, verbatim Lux logic. AURORA_PROBABILITY=1.0.
// ============================================================
#ifdef DIMENSION_TF
#define LUX_TF_AURORA_HEIGHT     12.5
#define LUX_TF_AURORA_BRIGHTNESS  5.5

vec2 luxHash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
float luxSimplexNoise(in vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    float m_ = step(a.y, a.x);
    vec2 o = vec2(m_, 1.0 - m_);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, luxHash22(i)),
                                  dot(b, luxHash22(i + o)),
                                  dot(c, luxHash22(i + 1.0)));
    return dot(n, vec3(70.0));
}
float luxRidgedNoise(vec2 coord, float scale, float time, float sharpness) {
    float s1 = luxSimplexNoise((coord + time) * scale);
    float s2 = luxSimplexNoise((coord.yx - time) * scale);
    float ridged = 1.0 - abs(s1 + s2);
    return pow(ridged, sharpness);
}
float luxAuroraNoise(vec2 coord, float scale, float time, float sharpness, float localY) {
    float n = luxRidgedNoise(coord, scale, time, sharpness);
    n *= texture2DLod(noisetex, coord * 2.5 + time * 5.0, 0.0).r * 0.5 + 0.5;
    n = n * n * (3.0 - 2.0 * n);
    return n * (1.0 - localY);
}

const vec3 luxAuroraBlue  = vec3(0.1, 0.2, 1.0);
const vec3 luxAuroraRed   = vec3(1.0, 0.1, 0.6);
const vec3 luxAuroraGreen = vec3(0.1, 1.0, 0.2);
vec3 luxGetAuroraColor(in vec2 coord, float scale) {
    float n1   = luxSimplexNoise(coord * scale * 0.7) * 0.5 + 0.5;
    float n2   = luxSimplexNoise(coord.yx * scale * 0.7) * 0.5 + 0.5;
    float mixF = luxSimplexNoise((coord - frameTimeCounter * 0.05) * scale * 0.2) * 0.5 + 0.5;
    vec3 col   = mix(mix(luxAuroraBlue, luxAuroraGreen, n1),
                     mix(luxAuroraBlue, luxAuroraRed,   n2), mixF);
    return col * col;
}

vec3 GetLuxTFAurora(vec3 viewPos, float dither) {
    float cosT = dot(normalize(viewPos), upVec);
    if (cosT < 0.0) return vec3(0.0);

    float horizonInt  = 1.0 - exp2(-cosT * 20.0);
    float sharpness   = mix(1.0, 16.0,
        sqrt(max(1.0 - pow2(cosT - 1.0), 0.0)) * horizonInt);
    vec3 worldDir     = normalize(mat3(gbufferModelViewInverse) * viewPos);

    #ifdef DEFERRED1
        const int luxIter = 12;
    #else
        const int luxIter = 8;
    #endif
    float fIter = float(luxIter);
    float iMult = 12.0 / fIter;

    float auroraAlpha = 0.0;
    for (int i = 0; i < luxIter; i++) {
        if (auroraAlpha > 0.99) break;
        vec2 planeCoord = worldDir.xz
            * (LUX_TF_AURORA_HEIGHT + (float(i) + dither) * iMult)
            / worldDir.y * 0.0005;
        vec2 coord   = planeCoord + cameraPosition.xz * 0.0001;
        float localY = (float(i) + dither) / fIter;
        float noise  = luxAuroraNoise(coord, 35.0, frameTimeCounter * 0.0003, sharpness, localY);
        auroraAlpha  = mix(auroraAlpha, 1.0, noise / fIter * 6.0);
    }
    auroraAlpha *= horizonInt;
    if (auroraAlpha < 0.005) return vec3(0.0);
    auroraAlpha = auroraAlpha * auroraAlpha * 0.05;

    return luxGetAuroraColor(worldDir.xz, 1.7) * LUX_TF_AURORA_BRIGHTNESS * auroraAlpha;
}

// Additive blue-purple horizon haze for TF sky pixels.
vec3 GetTFSkyHaze(float VdotU) {
    vec3  hazeColor     = vec3(TF_SKY_HAZE_R, TF_SKY_HAZE_G, TF_SKY_HAZE_B) * TF_SKY_HAZE_I;
    float horizonWeight = max(1.0 - abs(VdotU) * 2.5, 0.0);
          horizonWeight = horizonWeight * horizonWeight;
    return hazeColor * horizonWeight;
}
#endif // DIMENSION_TF

// ============================================================
// ---- Solas Shader V3.3 aurora helpers (Ratlantis) ----------
// Always-on (bypasses moonVisibility/wetness gating).
// Colors: green-cyan low / purple-blue high (Solas defaults).
// ============================================================
#ifdef DIMENSION_RATLANTIS
#define SOLAS_RAT_AURORA_BRIGHTNESS 1.25
#define SOLAS_RAT_KARMAN_LINE       100000.0

float solasAuroraDistortedNoise(vec2 coord, float kpIndex, float pulse, float longPulse, float altitudeFactor50k) {
    float t = frameTimeCounter * 0.125;
    vec2 dc = coord;

    float baseAngle = t * 0.00012;
    float ca = cos(baseAngle), sa = sin(baseAngle);
    dc = vec2(ca * dc.x - sa * dc.y, sa * dc.x + ca * dc.y);

    vec2 flowUV = dc * 0.35 + vec2(sin(t * 0.0012), cos(t * 0.0010));
    float f = texture2DLod(noisetex, flowUV, 0.0).r * 2.0 - 1.0;
    vec2 curlDir = normalize(vec2(cos(f * 6.2831853 + t * 0.12),
                                  sin(f * 6.2831853 + t * 0.12)));
    vec2 warping = curlDir * f;
    dc += warping * 0.125;
    dc.y *= 0.75;
    dc.x *= 1.5;

    float zenithDist = abs(coord.y + 1.0);
    float arc = mix(exp(-3.0 * zenithDist * zenithDist), 0.125, altitudeFactor50k);
    arc *= 0.65 + 0.35 * f;

    float sheet = texture2DLod(noisetex,
        vec2(dc.x * 1.25, dc.y * 0.5 + frameTimeCounter * 0.0025), 0.0).r;
    sheet *= sheet * sheet * 2.0;

    float rays = texture2DLod(noisetex,
        vec2(dc.x * 5.0, dc.y * 2.0) +
        vec2(-frameTimeCounter * 0.0015, frameTimeCounter * 0.0025), 0.0).r;
    float flashTime = sin(frameTimeCounter + dc.x * 64.0 + warping.x * 32.0);
    flashTime = clamp01((flashTime - 0.4) / 0.6);

    float r4 = rays * rays; r4 = r4 * r4;
    float r8 = r4 * r4;
    float r12 = r8 * r4;

    float aurora = sheet * arc * ((25.0 + longPulse * 25.0)
                   + r8 * 7500.0
                   + r12 * flashTime * 100000.0);
    return max(aurora, 0.0);
}

vec3 GetSolasRatlantisAurora(vec3 viewPos, float dither) {
    vec3 worldPos  = mat3(gbufferModelViewInverse) * viewPos;
    if (worldPos.y <= 0.0) return vec3(0.0);
    vec3 nWorldPos = normalize(worldPos);

    float altitudeFactor    = min(max(cameraPosition.y, 0.0) / SOLAS_RAT_KARMAN_LINE, 1.0);
    float altitudeFactor50k = min(max(cameraPosition.y, 0.0) / 50000.0, 1.0);
    worldPos.y *= 1.0 - altitudeFactor * 0.66;

    float fade = pow(max(nWorldPos.y, 0.0), 0.125);
    float fadeMix = altitudeFactor50k * altitudeFactor50k;
    fade = mix(fade, (1.0 - fade) * float(nWorldPos.y < 0.0), fadeMix);
    fade = fade * fade * fade * fade;

    float kpIndex = float(abs(worldDay % 9 - worldDay % 4));
    kpIndex = clamp(kpIndex, 0.0, 9.0);

    float pulse = 0.5 + 0.5 * sin(frameTimeCounter * 0.08
                                   + sin(frameTimeCounter * 0.013) * 0.6);
    pulse = clamp01((pulse - 0.15) / 0.70);
    float longPulse = sin(frameTimeCounter * 0.025
                          + sin(frameTimeCounter * 0.004) * 0.8);
    longPulse = longPulse * (1.0 - 0.15 * abs(longPulse));

    kpIndex *= 1.0 + longPulse * 0.25;
    kpIndex /= 9.0;

    float visibility = kpIndex * (1.0 + max(longPulse * 0.5, 0.0));
    visibility = min(visibility, 2.0) * SOLAS_RAT_AURORA_BRIGHTNESS;
    if (visibility <= 0.005) return vec3(0.0);

    vec3 aurora = vec3(0.0);
    int  samples = int(8.0 + kpIndex * 8.0);
    float sampleStep  = 1.0 / float(samples);
    float currentStep = dither * sampleStep;

    float tiltFactor = 0.15 + kpIndex * 0.15;
    worldPos.xz -= worldPos.y * vec2(tiltFactor, tiltFactor * 2.0);

    for (int i = 0; i < samples; i++) {
        float planeFactor = (20.0 - kpIndex * 10.0
                             + altitudeFactor * 20.0
                             + pow(clamp(nWorldPos.y, 0.0, 1.0), 0.25) * 15.0
                             + currentStep * (10.0 + kpIndex * 5.0));
        vec3  planeCoord = worldPos * (planeFactor / worldPos.y) * 0.05;
        vec2  coord      = planeCoord.xz + cameraPosition.xz * 0.0005;

        float WEhorizon       = clamp(pow(1.0 - abs(planeCoord.x * 0.1), 4.0), 0.0, 1.0);
        float k3 = kpIndex * kpIndex * kpIndex;
        float k4 = k3 * kpIndex;
        float auroraNBias     = clamp((-planeCoord.x * 0.5 - planeCoord.z) * 0.25
                                      + k4 * 2.0, 0.0, 1.0);
        float minFactor       = max(0.05 - altitudeFactor50k * (1.0 - altitudeFactor) * 0.25
                                    + altitudeFactor * 0.04, 0.0125);
        float distanceFactor  = clamp(1.0 - length(planeCoord.xz) * minFactor, 0.0, 1.0)
                                * mix(auroraNBias, 1.0, altitudeFactor)
                                * mix(WEhorizon, clamp(pow(abs(planeCoord.z * 0.1),
                                        5.0 - kpIndex * 3.0), 0.0, 1.0), altitudeFactor50k);

        if (distanceFactor > 0.0) {
            float auroraSample = solasAuroraDistortedNoise(coord * 0.025, kpIndex, pulse, longPulse, altitudeFactor50k);
            float colorMixer   = pow(currentStep, 0.65 + altitudeFactor50k + k3 * pulse * 0.1);
            float attenuation  = exp2(-4.0 * float(i) * sampleStep);

            vec3 lowA  = vec3(0.45, 1.55, 0.0);
            vec3 upA   = vec3(0.95 + k3 * pulse, 0.10, 1.05);
            vec3 auroraA = mix(lowA, upA,
                               clamp01(mix(colorMixer, 1.0 - colorMixer, altitudeFactor50k)))
                           * mix(attenuation, 1.0 - attenuation, altitudeFactor);

            aurora += auroraA * auroraSample * sqrt(distanceFactor);
        }
        currentStep += sampleStep;
    }

    return aurora * visibility * sampleStep * fade;
}
#endif // DIMENSION_RATLANTIS

// ============================================================
// ---- Original EP aurora (Overworld only) -------------------
// ============================================================
#if !defined DIMENSION_TF && !defined DIMENSION_RATLANTIS

float GetAuroraVisibility(in float VdotU, float VdotUAmount) {
    float visibility = sqrt1(clamp01(mix(1.0, VdotU, VdotUAmount) * (AURORA_DRAW_DISTANCE * 1.125 + 0.75) - 0.225)) - sunVisibility - maxBlindnessDarkness;

    #ifdef CLEAR_SKY_WHEN_RAINING
        visibility -= rainFactor * 0.5;
    #else
        visibility -= rainFactor;
    #endif

    visibility *= 1.0 - VdotU * 0.9 * VdotUAmount;

    #if AURORA_CONDITION == 1 || AURORA_CONDITION == 3
        visibility -= moonPhase;
    #endif
    #if AURORA_CONDITION == 2 || AURORA_CONDITION == 3
        visibility *= inSnowy;
    #endif
    #if AURORA_CONDITION == 4
        visibility = max(visibility * inSnowy, visibility - moonPhase);
    #endif
    #if AURORA_CONDITION == -1
        visibility *= clamp01(max(moonPhase, 1) % 4);
    #endif

    #if RANDOM_AURORA > 0
        float randomValue = hash11(float(worldDay));
        if (randomValue > RANDOM_AURORA * 0.1) {
            visibility = -1.0;
        }
    #endif

    return visibility;
}

vec3 auroraUpA[] = vec3[](
    vec3(112.0, 36.0, 192.0),
    vec3(112.0, 80.0, 255.0),
    vec3(168.0, 36.0, 88.0),
    vec3(255.0, 68.0, 124.0),
    vec3(72.0, 96.0, 192.0),
    vec3(24.0, 255.0, 140.0),
    vec3(255.0, 220.0, 255.0),
    vec3(64.0, 255.0, 255.0),
    vec3(0.0, 20.0, 60.0),
    vec3(132.0, 0.0, 200.0),
    vec3(120.0, 212.0, 56.0),
    vec3(0.0, 255.0, 255.0),
    vec3(255.0, 80.0, 112.0)
);
vec3 auroraDownA[] = vec3[](
    vec3(96.0, 255.0, 192.0),
    vec3(80.0, 255.0, 180.0),
    vec3(60.0, 184.0, 152.0),
    vec3(160.0, 96.0, 255.0),
    vec3(172.0, 44.0, 88.0),
    vec3(108.0, 72.0, 255.0),
    vec3(68.0, 255.0, 72.0),
    vec3(128.0, 64.0, 128.0),
    vec3(0.0, 24.0, 36.0),
    vec3(56.0, 168.0, 255.0),
    vec3(176.0, 88.0, 72.0),
    vec3(180.0, 0.0, 0.0),
    vec3(80.0, 255.0, 180.0)
);

vec2 warpAuroraCoords(vec2 coord, float warpAmount) {
    float angle    = texture2D(noisetex, coord * 0.5).r * 6.28318 * warpAmount;
    float strength = texture2D(noisetex, coord * 0.7 + 0.5).r * warpAmount;
    vec2 offset    = vec2(cos(angle), sin(angle)) * strength;
    return coord + offset;
}

void GetAuroraColor(in vec2 wpos, out vec3 auroraUp, out vec3 auroraDown) {
    #ifdef RGB_AURORA
        auroraUp   = getRainbowColor(wpos, 0.06);
        auroraDown = getRainbowColor(wpos, 0.05);
    #elif AURORA_COLOR_PRESET == 0
        auroraUp   = vec3(AURORA_UP_R, AURORA_UP_G, AURORA_UP_B);
        auroraDown = vec3(AURORA_DOWN_R, AURORA_DOWN_G, AURORA_DOWN_B);
    #elif AURORA_COLOR_PRESET == -1
        float randomValue = hash11(float(worldDay));
        randomValue = pow(randomValue, 0.7);
        float transitionsPerNight = min(randomValue * 2.0, 1.75);
        float idx, frac = modf(nightFactor * transitionsPerNight, idx);
        int dayOffset   = worldDay % auroraUpA.length();
        int colorsCount = auroraUpA.length();
        int i0 = (int(idx) + dayOffset) % colorsCount;
        int i1 = (i0 + 1) % colorsCount;
        vec3 oklabUp0   = rgb2oklab(auroraUpA[i0]   / 255.0);
        vec3 oklabUp1   = rgb2oklab(auroraUpA[i1]   / 255.0);
        vec3 oklabDown0 = rgb2oklab(auroraDownA[i0] / 255.0);
        vec3 oklabDown1 = rgb2oklab(auroraDownA[i1] / 255.0);
        auroraUp   = oklab2rgb(mix(oklabUp0,   oklabUp1,   frac)) * 255.0;
        auroraDown = oklab2rgb(mix(oklabDown0, oklabDown1, frac)) * 255.0;
    #else
        #if AURORA_COLOR_PRESET == 1
            int p = worldDay % auroraUpA.length();
        #elif AURORA_COLOR_PRESET == 2
            int p = worldDay % (auroraUpA.length() * 8) / 8;
        #else
            const int p = AURORA_COLOR_PRESET - 2;
        #endif
        auroraUp   = auroraUpA[p];
        auroraDown = auroraDownA[p];
    #endif
    auroraUp   = max(auroraUp,   vec3(0.001));
    auroraDown = max(auroraDown, vec3(0.001));
    auroraUp   *= (AURORA_UP_I   * 0.093 + 3.1)  / GetLuminance(auroraUp);
    auroraDown *= (AURORA_DOWN_I * 0.245 + 8.15) / GetLuminance(auroraDown);
    #if AURORA_SATURATION != 10
        auroraUp   = rgb2hsv(auroraUp);
        auroraUp.g *= AURORA_SATURATION * 0.1;
        auroraUp   = hsv2rgb(auroraUp);
        auroraDown = rgb2hsv(auroraDown);
        auroraDown.g *= AURORA_SATURATION * 0.1;
        auroraDown = hsv2rgb(auroraDown);
    #endif
}

#endif // !DIMENSION_TF && !DIMENSION_RATLANTIS

// getAuroraAmbientColor: OW uses aurora visibility gating; TF/Ratlantis return input unchanged.
#if defined DIMENSION_TF || defined DIMENSION_RATLANTIS
vec3 getAuroraAmbientColor(vec3 color, vec3 viewPos, float multiplier, float influence, float VdotUAmount) {
    return color;
}
#else
vec3 getAuroraAmbientColor(vec3 color, vec3 viewPos, float multiplier, float influence, float VdotUAmount) {
    float visibility = GetAuroraVisibility(0.5, VdotUAmount);
    if (visibility > 0) {
        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        wpos.xz /= (abs(wpos.y) + length(wpos.xz));

        vec3 auroraUp, auroraDown;
        GetAuroraColor(wpos.xz, auroraUp, auroraDown);

        vec3 auroraColor = mix(auroraUp, auroraDown, 0.8);
        #ifdef COMPOSITE1
            visibility *= influence;
            return mix(color, auroraColor, visibility);
        #endif
        auroraColor *= multiplier;
        visibility  *= influence;
        #ifdef DEFERRED1
            return mix(color, saturateColors(auroraColor, 0.8) * visibility * 0.45, visibility);
        #endif
        float luminanceColor = GetLuminance(color);
        vec3 newColor = mix(color, mix(color, vec3(luminanceColor), 0.88), visibility);
        newColor *= mix(vec3(1.0), auroraColor * luminanceColor * 10.0, visibility);
        return clamp01(newColor);
    }
    return color;
}
#endif

vec3 GetAuroraBorealis(vec3 viewPos, float VdotU, float dither) {
    #ifdef DIMENSION_TF
        return GetLuxTFAurora(viewPos, dither);

    #elif defined DIMENSION_RATLANTIS
        return GetSolasRatlantisAurora(viewPos, dither);

    #else
        // Original EP Overworld aurora
        float visibility = GetAuroraVisibility(VdotU, 1.0);
        if (visibility > 0.0) {
            vec3 aurora = vec3(0.0);
            vec3 wpos = mat3(gbufferModelViewInverse) * viewPos;
                 wpos.xz /= wpos.y;
            vec2 cameraPositionM = cameraPosition.xz * 0.0075;
                 cameraPositionM.x += syncedTime * 0.04;

            #ifdef DEFERRED1
                int sampleCount  = 25;
                int sampleCountP = sampleCount + 5;
            #else
                int sampleCount  = 10;
                int sampleCountP = sampleCount + 10;
            #endif

            float ditherM     = dither + 5.0;
            float auroraAnimate = frameTimeCounter * 0.001;

            vec3 auroraUp, auroraDown;
            GetAuroraColor(wpos.xz, auroraUp, auroraDown);

            for (int i = 0; i < sampleCount; i++) {
                float current = pow2((i + ditherM) / sampleCountP);
                vec2 planePos = wpos.xz * (AURORA_SIZE * 0.8 + current) * 11.0 * AURORA_NOISE_SCALE + cameraPositionM;

                float noise;
                #if AURORA_STYLE == 1
                    planePos = floor(planePos) * 0.0007;
                    #if AURORA_PATTERN_WARP > 0
                        planePos = warpAuroraCoords(planePos, AURORA_PATTERN_WARP * 0.0057);
                    #endif
                    noise = texture2DLod(noisetex, planePos, 0.0).b;
                    noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));
                    noise *= pow1_5(texture2DLod(noisetex, planePos * 100.0 + auroraAnimate, 0.0).b);
                #else
                    planePos *= 0.0007;
                    #if AURORA_PATTERN_WARP > 0
                        planePos = warpAuroraCoords(planePos, AURORA_PATTERN_WARP * 0.0082);
                    #endif
                    noise = texture2DLod(noisetex, planePos, 0.0).r;
                    noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));
                    noise *= texture2DLod(noisetex, planePos * 3.0 + auroraAnimate, 0.0).b;
                    noise *= texture2DLod(noisetex, planePos * 5.0 - auroraAnimate, 0.0).b;
                #endif

                float currentM = 1.0 - current;
                aurora += noise * currentM * mix(auroraUp, auroraDown, pow(pow2(currentM), AURORA_COLOR_MIX_POWER));
            }

            #if AURORA_STYLE == 1
                aurora *= 1.3;
            #else
                aurora *= 1.8;
            #endif

            #ifdef ATM_COLOR_MULTS
                aurora *= sqrtAtmColorMult;
            #endif

            return aurora * visibility / sampleCount;
        }
        return vec3(0.0);
    #endif
}
#endif // AURORA_BOREALIS_GLSL
