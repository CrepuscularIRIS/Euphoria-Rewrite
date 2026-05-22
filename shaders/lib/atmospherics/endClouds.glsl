#ifndef END_CLOUDS_GLSL
#define END_CLOUDS_GLSL

// ---- Solas V3.3 End Volumetric Cloud Disk (END_DISK) -------------------------
// Ported from shaders/lib/atmosphere/volumetricClouds.glsl by Septonious
// License: MIT  https://opensource.org/licenses/MIT
//
// Adaptations for Euphoria-Rewrite / EP:
//   fmix(a,b,t)          → mix(a, b, clamp01(t))
//   pow8(x)              → pow4(pow2(x))
//   texture2DShadow/ToShadow → PlayerToShadow + EP distortion + shadow2D
//   endLightCol          → endLightColor   (EP lightAndAmbientColors.glsl)
//   Removed: END_FLASHES, END_TIME_TILT, END_67, DISTANT_HORIZONS branches

#ifdef END_DISK_CLOUDS

float epEndProtoplanetaryDisk(vec2 coord) {
    const float whirl = -5.0;
    const float arms  =  5.0;
    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01,
                 sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow4(1.0 - coord.y);
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;
    return min(spiral * 1.75, 1.5);
}

void epGetEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
    rayPos *= 0.00025;

    float worleyNoise = (1.0 - texture2DLod(noisetex, rayPos + wind * 0.5, 0.0).g) * 0.5 + 0.25;
    float perlinNoise  = texture2DLod(noisetex, rayPos + wind * 0.5, 0.0).r;
    float noiseBase    = perlinNoise * 0.5 + worleyNoise * 0.5;

    float detailZ      = floor(attenuation * END_DISK_THICKNESS) * 0.05;
    float noiseDetailA = texture2DLod(noisetex, rayPos - wind + detailZ, 0.0).b;
    float noiseDetailB = texture2DLod(noisetex, rayPos - wind + detailZ + 0.05, 0.0).b;
    float noiseDetail  = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

    float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 5.0);
    noiseCoverage *= noiseCoverage * 5.0;

    noise = mix(noiseBase, noiseDetail, 0.025 * float(noiseBase > 0.0)) * 22.0 - noiseCoverage;
    noise = max(noise - END_DISK_AMOUNT - 1.0 + epEndProtoplanetaryDisk(rayPos), 0.0);
    noise /= sqrt(noise * noise + 0.25);
}

// nWorldPos : normalize(mat3(gbufferModelViewInverse) * nViewPos)  from deferred1
// VoS       : dot(nViewPos, sunVec)
// dither    : blue-noise dither
// currentDepth : cloud linear depth (inout, updated for gbuffers_water discard)
void computeEndDiskClouds(inout vec4 vc, vec3 nWorldPos,
                          float VoS, float dither,
                          inout float currentDepth) {
    float cloudTop   = END_DISK_HEIGHT + END_DISK_THICKNESS * 10.0;
    float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
    float upperPlane = (cloudTop       - cameraPosition.y) / nWorldPos.y;
    float minDist    = max(min(lowerPlane, upperPlane), 0.0);
    float maxDist    = max(lowerPlane, upperPlane);

    float planeDiff  = maxDist - minDist;
    float rayLength  = END_DISK_THICKNESS * 6.0;
    rayLength       /= nWorldPos.y * nWorldPos.y * 6.0 + 1.0;

    int sampleCount = int(min(planeDiff / rayLength, 64.0) + dither);
    if (maxDist < 0.0 || sampleCount <= 0) return;

    float cloud         = 0.0;
    float cloudAlpha    = 0.0;
    float cloudLighting = 0.0;

    float halfVoLSqrt = clamp(VoS, 0.0, 1.0) * 0.5 + 0.5;
    float scattering  = pow4(pow2(halfVoLSqrt)); // pow8

    vec3  rayPos            = cameraPosition + minDist * nWorldPos + nWorldPos * (rayLength * dither);
    vec3  sampleStep        = nWorldPos * rayLength;
    float maxDepth          = currentDepth;
    float minimalNoise      = 0.25 + dither * 0.25;
    float sampleTotalLength = minDist + rayLength * dither;

    vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

    vec3 worldLightDir = normalize(mat3(gbufferModelViewInverse) * sunVec);
    worldLightDir.xz *= 32.0;

    for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
        if (cloudAlpha > 0.99) break;

        vec3  worldPos = rayPos - cameraPosition;
        float rayDist  = length(worldPos.xz) * 0.1;
        float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

        float noise        = 0.0;
        float lightingNoise = 0.0;
        epGetEndCloudSample(rayPos.xz,                     wind, attenuation,                      noise);
        epGetEndCloudSample(rayPos.xz + worldLightDir.xz,  wind, attenuation + worldLightDir.y * 0.15, lightingNoise);

        float shadow1 = 1.0;
        #if SHADOW_QUALITY > -1
        if (rayDist < shadowDistance * 0.1) {
            vec3  sp    = PlayerToShadow(worldPos);
            float distb = length(sp.xy);
            float distF = 1.0 - shadowMapBias + distb * shadowMapBias;
            vec3  sc    = vec3(sp.xy / distF, sp.z * 0.2) * 0.5 + 0.5;
            shadow1     = clamp01(shadow2D(shadowtex0, sc).z);
        }
        #endif

        float sampleLighting = 0.05 + clamp(noise - lightingNoise * (0.9 - scattering * 0.15), 0.0, 0.95) * (1.5 + scattering);
        sampleLighting *= 1.0 - noise * 0.75;
        sampleLighting  = clamp01(sampleLighting);

        cloudLighting = mix(cloudLighting, sampleLighting, clamp01(noise * (1.0 - cloud * cloud)));

        noise     *= shadow1;
        cloud      = mix(cloud,      1.0, clamp01(noise));
        float fogN = noise * pow4(pow2(1.0 - smoothstep(8.0, 4000.0, rayDist)));
        cloudAlpha = mix(cloudAlpha, 1.0, clamp01(fogN));

        if (noise > minimalNoise && currentDepth == maxDepth)
            currentDepth = sampleTotalLength;
    }

    // Rebuild Solas-equivalent endLightCol via sqrt-gamma from BH light settings.
    // END_BHOLE_LIGHT_* defaults: R=0.76, G=0.67, B=0.65, I=1.45 → ~vec3(1.214, 0.944, 0.888)
    vec3 diskLightSqrt = vec3(END_BHOLE_LIGHT_R, END_BHOLE_LIGHT_G, END_BHOLE_LIGHT_B) * END_BHOLE_LIGHT_I;
    vec3 diskLightCol  = diskLightSqrt * diskLightSqrt;

    // Solas color/brightness: vec3(0.95, 1.0, 0.5) * endLightCol * cloudLighting * 0.35
    // No additive ambient term — clouds must go dark in unlit areas.
    vec3 cloudColor = vec3(0.95, 1.0, 0.5) * diskLightCol;
    cloudColor *= cloudLighting * 0.35;
    vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY);
}

#endif // END_DISK_CLOUDS
#endif // END_CLOUDS_GLSL
