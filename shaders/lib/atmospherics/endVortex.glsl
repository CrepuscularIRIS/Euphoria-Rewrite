#ifndef END_VORTEX_GLSL
#define END_VORTEX_GLSL

// Bliss v2.1.2 End storm migration.
// Oculus 1.20.1 does not reliably accept the extra deferred render target path
// needed for a persistent LUT, so the vortex is evaluated directly per pixel in
// deferred1.glsl. The density and lighting model stay source-faithful; only the
// lightning persistence falls back to a deterministic time hash.

#include "/lib/shaderSettings/endNebula.glsl"

#ifndef PI
#define PI 3.14159265359
#endif
#ifndef TAU
#define TAU 6.28318530718
#endif

const float vpRcpPi  = 1.0 / PI;
const float vpRcpTau = 1.0 / TAU;

vec3 vpHash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float vpHash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec3 vpCartToSphere(vec2 coord) {
    coord *= vec2(TAU, PI);
    vec2 lon = vec2(cos(coord.x), sin(coord.x)) * sin(coord.y);
    return vec3(lon.x, 2.0 * vpRcpPi * coord.y - 1.0, lon.y);
}

vec2 vpSphereToCartUnit(vec3 dir) {
    float lon = atan(-dir.x, -dir.z);
    float lat = acos(clamp(dir.y, -1.0, 1.0));
    return vec2(fract(lon * vpRcpTau + 0.5), lat * vpRcpPi);
}

vec2 vpSampleEndVortexLUT(vec3 worldDir) {
    vec2 baseUv = vpSphereToCartUnit(normalize(worldDir));
    return vec2((baseUv.x * 255.0 + 0.5) / 256.0,
                (baseUv.y * 254.0 + 1.5) / 256.0);
}

vec2 vpCurrentEndVortexLUTCoord() {
    return clamp(vec2((gl_FragCoord.x - 0.5) / 255.0,
                      (gl_FragCoord.y - 1.5) / 254.0), 0.0, 1.0);
}

float vpLightningFlash() {
    float eventTime = frameTimeCounter * 0.2;
    float cycle = floor(eventTime);
    float timeSince = fract(eventTime);
    float trigger = step(0.92, vpHash11(cycle + 17.0));
    return 0.3 * trigger * exp(-timeSince * 3.5);
}

vec3 vpLightningOffset() {
    return vpHash31(floor(frameTimeCounter * 0.2) + 31.0) * 2.0 - 1.0;
}

float vpDensityAtPos(vec3 pos) {
    pos /= 18.0;
    pos.xz *= 0.5;
    vec3 p = floor(pos);
    vec3 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = p.xz + f.xz + p.y * vec2(0.0, 193.0);
    vec2 coord = uv / 512.0;
    vec2 xy = texture2DLod(noisetex, coord, 0.0).yx;
    return mix(xy.r, xy.g, f.y);
}

void vpSwirlAroundOrigin(inout vec3 alteredOrigin, vec3 origin) {
    float radiance = 2.39996 + alteredOrigin.y / 1.5 + frameTimeCounter / 50.0;
    float s = sin(radiance);
    float c = cos(radiance);
    mat2 rotationMatrix = mat2(c, -s, s, c);

    float swirlBounds = clamp(sqrt(length(vec3(origin.x, origin.y - 100.0, origin.z)) / 200.0 - 1.0), 0.0, 1.0);
    alteredOrigin.xz = mix(alteredOrigin.xz * rotationMatrix, alteredOrigin.xz, swirlBounds);
}

void vpVolumeBounds(inout float volume, vec3 origin) {
    vec3 origin2 = origin - vec3(0.0, 100.0, 0.0);
    origin2.y *= 0.8;
    float bounds = max(1.0 - length(origin2) / 75.0, 0.0) * 5.0;

    const float radius = 150.0;
    const float thickness = 50.0 * radius;

    float torus = (thickness - clamp(pow(length(vec2(length(origin.xz) - radius, origin2.y)), 2.0) - radius, 0.0, thickness)) / thickness;
    volume = max(volume - bounds - torus, 0.0);
}

float vpFogShape(vec3 pos) {
    float vortexBounds = clamp(300.0 - length(pos), 0.0, 1.0);
    vec3 samplePos = pos * vec3(1.0, 1.0 / 48.0, 1.0);
    float voidZone = max(exp2(-sqrt(max(pos.y + 60.0, 0.0))), 0.0);

    vpSwirlAroundOrigin(samplePos, pos);

    float noise = vpDensityAtPos(samplePos * 12.0);
    float erosion = 1.0 - vpDensityAtPos((samplePos - frameTimeCounter / 20.0) * (124.0 + (1.0 - noise) * 7.0));
    float clumpyFog = max(exp(noise * -mix(10.0, 4.0, vortexBounds)) * mix(2.0, 1.0, vortexBounds) - erosion * 0.3, 0.0);

    vpVolumeBounds(clumpyFog, pos);
    return clumpyFog + voidZone;
}

float vpEndFogPhase(vec3 lightPos) {
    float mie = exp(length(lightPos) / -150.0);
    mie *= mie;
    mie *= mie;
    mie *= 100.0;
    return mie;
}

vec3 vpLightSourcePosition(vec3 worldPos, vec3 cameraPos, float vortexBounds) {
    vec3 vortexPos = worldPos - vec3(0.0, 200.0, 0.0);

    const float cellSize = 200.0;
    vec3 lightningPos = worldPos - cameraPos;
    lightningPos += fract(cameraPos / cellSize) * cellSize - cellSize * 0.5;

    lightningPos -= vpLightningOffset() * 2.5;

    return mix(lightningPos, vortexPos, vortexBounds);
}

vec3 vpLightSourceColors(float vortexBounds, float lightningFlash) {
    vec3 vortexColor = vec3(VORTEX_LIGHT_R, VORTEX_LIGHT_G, VORTEX_LIGHT_B);
    vec3 lightningColor = vec3(END_LIGHTNING_R, END_LIGHTNING_G, END_LIGHTNING_B) * lightningFlash;
    return mix(lightningColor, vortexColor, vortexBounds);
}

vec3 vpLightSourceLighting(vec3 startPos, vec3 lightPos, float noise, float density, vec3 lightColor) {
    float phase = vpEndFogPhase(lightPos);
    float shadow = 0.0;

    for (int j = 0; j < 3; j++) {
        vec3 shadowSamplePos = startPos - lightPos * (0.05 + float(j) * (0.25 + noise * 0.15));
        shadow += vpFogShape(shadowSamplePos);
    }

    vec3 finalLighting = lightColor * phase * exp(shadow * -10.0);
    finalLighting += lightColor * phase * phase
                  * (1.0 - exp((shadow * shadow * shadow) * vec3(-0.6, -2.0, -2.0)))
                  * (1.0 - exp(-density * density));

    return finalLighting;
}

vec4 GetEndVortex(vec3 viewPosition, float dither, float dither2) {
    vec3 wpos = mat3(gbufferModelViewInverse) * viewPosition + gbufferModelViewInverse[3].xyz;
    vec3 dVWorld = wpos - gbufferModelViewInverse[3].xyz;

    float maxLength = min(length(dVWorld), 32.0 * 12.0) / length(dVWorld);
    dVWorld *= maxLength;

    float dL = length(dVWorld);
    const float expFactor = 11.0;
    const int sampleCount = VORTEX_STEPS;

    vec3 color = vec3(0.0);
    float absorbance = 1.0;
    float skyPhase = 0.5 + pow(clamp(normalize(wpos).y * 0.5 + 0.5, 0.0, 1.0), 4.0) * 5.0;
    float lightningFlash = vpLightningFlash();

    for (int i = 0; i < sampleCount; i++) {
        float fi = float(i);
        float d = (pow(expFactor, (fi + dither) / float(sampleCount)) / expFactor - 1.0 / expFactor) / (1.0 - 1.0 / expFactor);
        float dd = pow(expFactor, (fi + dither) / float(sampleCount)) * log(expFactor) / float(sampleCount) / (expFactor - 1.0);

        vec3 progressW = gbufferModelViewInverse[3].xyz + cameraPosition + d * dVWorld;

        #ifdef END_LIGHTNING
            float vortexBounds = clamp(300.0 - length(progressW), 0.0, 1.0);
        #else
            float vortexBounds = 1.0;
        #endif

        vec3 lightPosition = vpLightSourcePosition(progressW, cameraPosition, vortexBounds);
        vec3 lightColors = vpLightSourceColors(vortexBounds, lightningFlash);

        float volumeDensity = vpFogShape(progressW);
        float clearArea = 1.0 - min(max(1.0 - length(progressW - cameraPosition) / 100.0, 0.0), 1.0);
        float stormDensity = min(volumeDensity, clearArea * clearArea * END_VORTEX_DENSITY);
        float volumeCoeff = exp(-stormDensity * dd * dL);

        vec3 lightSources = vpLightSourceLighting(progressW, lightPosition, dither2, volumeDensity, lightColors);
        vec3 indirect = vec3(0.5, 0.75, 1.0) * 0.2 * (exp((volumeDensity * volumeDensity) * -50.0) * 0.9 + 0.1);
        vec3 stormLighting = indirect + lightSources;

        color += (stormLighting - stormLighting * volumeCoeff) * absorbance;
        absorbance *= volumeCoeff;

        float hazeDensity = 0.001 * END_HAZE_DENSITY;
        vec3 hazeLighting = vec3(0.3, 0.6, 1.0) * skyPhase;
        color += (hazeLighting - hazeLighting * exp(-hazeDensity * dd * dL)) * absorbance;
    }

    return vec4(color, absorbance);
}

#endif // END_VORTEX_GLSL
