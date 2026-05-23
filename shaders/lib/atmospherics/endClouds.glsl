#ifndef END_CLOUDS_GLSL
#define END_CLOUDS_GLSL

// Solas V3.3 End disk volumetric clouds.
// This keeps the Solas density and lighting model, adapted only where EP's
// shadow-space helpers differ from Solas.

#ifdef END_DISK_CLOUDS

float epEndProtoplanetaryDisk(vec2 coord) {
    const float whirl = -5.0;
    const float arms = 5.0;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01,
                 sqrt(coord.x * coord.x + coord.y * coord.y));

    float center = pow4(1.0 - coord.y) * 1.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;
    return spiral;
}

void epGetEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
    rayPos *= 0.00025;

    float worleyNoise = (1.0 - texture2DLod(solasEndNoiseTex, rayPos + wind * 0.5, 0.0).g) * 0.5 + 0.25;
    float perlinNoise = texture2DLod(solasEndNoiseTex, rayPos + wind * 0.5, 0.0).r;
    float noiseBase = perlinNoise * 0.5 + worleyNoise * 0.5;

    float detailZ = floor(attenuation * END_DISK_THICKNESS) * 0.05;
    float noiseDetailA = texture2DLod(solasEndNoiseTex, rayPos - wind + detailZ, 0.0).b;
    float noiseDetailB = texture2DLod(solasEndNoiseTex, rayPos - wind + detailZ + 0.05, 0.0).b;
    float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

    float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 6.0);
    noiseCoverage *= noiseCoverage * 6.0;

    noise = mix(noiseBase, noiseDetail, 0.025 * float(noiseBase > 0.0)) * 22.0 - noiseCoverage;
    noise = max(noise - END_DISK_AMOUNT - 1.0 + epEndProtoplanetaryDisk(rayPos) * 2.0, 0.0);
    noise /= sqrt(noise * noise + 0.25);
}

void computeEndDiskClouds(inout vec4 vc, vec3 nWorldPos,
                          float VoS, float dither,
                          inout float currentDepth) {
    VoS = clamp01(VoS);

    float cloudTop = END_DISK_HEIGHT + END_DISK_THICKNESS * 10.0;
    float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
    float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
    float minDist = max(min(lowerPlane, upperPlane), 0.0);
    float maxDist = max(lowerPlane, upperPlane);

    float planeDifference = maxDist - minDist;
    float rayLength = END_DISK_THICKNESS * 6.0;
    rayLength /= nWorldPos.y * nWorldPos.y * 6.0 + 1.0;

    int sampleCount = int(min(planeDifference / rayLength, 64.0) + dither);
    if (maxDist < 0.0 || sampleCount <= 0) return;

    float cloud = 0.0;
    float cloudAlpha = 0.0;
    float cloudLighting = 0.0;

    float halfVoLSqrt = VoS * 0.5 + 0.5;
    float scattering = pow4(pow2(halfVoLSqrt));

    vec3 worldLightDir = normalize(mat3(gbufferModelViewInverse) * sunVec);
    worldLightDir.xz *= 32.0;

    vec3 rayPos = cameraPosition + minDist * nWorldPos + nWorldPos * (rayLength * dither);
    vec3 sampleStep = nWorldPos * rayLength;
    float maxDepth = currentDepth;
    float minimalNoise = 0.25 + dither * 0.25;
    float sampleTotalLength = minDist + rayLength * dither;
    vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

    for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
        if (cloudAlpha > 0.99) break;

        vec3 sampleWorldPos = rayPos - cameraPosition;
        float shadow1 = 1.0;

        #if SHADOW_QUALITY > -1
            vec3 sp = PlayerToShadow(sampleWorldPos);
            float distb = length(sp.xy);
            float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
            sp.xy /= distortFactor;
            sp.z *= 0.2;
            sp = sp * 0.5 + 0.5;
            if (clamp(sp.x, 0.0, 1.0) == sp.x &&
                clamp(sp.y, 0.0, 1.0) == sp.y &&
                clamp(sp.z, 0.0, 1.0) == sp.z) {
                shadow1 = clamp01(shadow2D(shadowtex1, sp).x);
            }
        #endif

        float noise = 0.0;
        float lightingNoise = 0.0;
        float rayDistance = length(sampleWorldPos.xz) * 0.1;
        float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

        epGetEndCloudSample(rayPos.xz, wind, attenuation, noise);
        epGetEndCloudSample(rayPos.xz + worldLightDir.xz, wind, attenuation, lightingNoise);

        float powder = 1.0 - 0.925 * exp(-pow(noise, 1.0 + noise * 7.0));
        float directionalScattering = 1.0 - exp(-2.0 * (noise - lightingNoise * 0.9));
        float sampleLighting = clamp((0.125 + attenuation * 0.875) * powder * directionalScattering * 2.0, 0.0, 1.0);

        if (length(sampleWorldPos) < shadowDistance) {
            cloudLighting *= 0.5 + shadow1 * 0.5;
        }

        cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
        cloud = mix(cloud, 1.0, noise);
        noise *= pow4(pow2(smoothstep(4000.0, 8.0, rayDistance)));
        cloudAlpha = mix(cloudAlpha, 1.0, noise);

        if (noise > minimalNoise && currentDepth == maxDepth) {
            currentDepth = sampleTotalLength;
        }
    }

    vec3 diskLightSqrt = vec3(END_BHOLE_LIGHT_R, END_BHOLE_LIGHT_G, END_BHOLE_LIGHT_B) * END_BHOLE_LIGHT_I;
    vec3 solasDiskLight = vec3(0.95, 1.0, 0.5) * (diskLightSqrt * diskLightSqrt);
    vec3 euphoriaDiskLight = endLightColor * vec3(1.8, 2.0, 2.35) + ambientColor * 0.9;
    vec3 cloudColor = max(solasDiskLight, euphoriaDiskLight);
    float cloudLuma = max(max(cloudColor.r, cloudColor.g), cloudColor.b);
    cloudColor = mix(cloudColor, vec3(cloudLuma), 0.35);
    cloudColor *= cloudLighting * (1.35 + scattering * 1.2);

    vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY);
}

#endif // END_DISK_CLOUDS
#endif // END_CLOUDS_GLSL
