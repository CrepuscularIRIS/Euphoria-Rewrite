#ifndef END_CLOUDS_GLSL
#define END_CLOUDS_GLSL

#ifdef END_DISK_CLOUDS

float epEndProtoplanetaryDisk(vec2 coord) {
    const float whirl = -5.0;
    const float arms = 5.0;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.01,
                 sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow4(1.0 - coord.y) * 1.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return min(spiral * 1.75, 1.5);
}

void epGetEndCloudSample(vec2 rayPos, vec2 wind, float attenuation, inout float noise) {
    rayPos *= 0.00025;

    float worleyNoise = (1.0 - texture2D(solasEndNoiseTex, rayPos + wind * 0.5).g) * 0.5 + 0.25;
    float perlinNoise = texture2D(solasEndNoiseTex, rayPos + wind * 0.5).r;
    float noiseBase = perlinNoise * 0.5 + worleyNoise * 0.5;

    float detailZ = floor(attenuation * END_DISK_THICKNESS) * 0.05;
    float noiseDetailA = texture2D(solasEndNoiseTex, rayPos - wind + detailZ).b;
    float noiseDetailB = texture2D(solasEndNoiseTex, rayPos - wind + detailZ + 0.05).b;
    float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * END_DISK_THICKNESS));

    float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.14 : 5.0);
    noiseCoverage *= noiseCoverage * 5.0;

    noise = mix(noiseBase, noiseDetail, 0.025 * float(noiseBase > 0.0)) * 22.0 - noiseCoverage;
    noise = max(noise - END_DISK_AMOUNT - 1.0 + epEndProtoplanetaryDisk(rayPos), 0.0);
    noise /= sqrt(noise * noise + 0.25);
}

void computeEndDiskClouds(inout vec4 vc, vec3 viewPos, float z, float dither, inout float currentDepth) {
    float visibility = float(0.56 < z);
    visibility *= 1.0 - maxBlindnessDarkness;
    if (visibility <= 0.0) return;

    vec3 nViewPos = normalize(viewPos);
    vec3 worldPos = ViewToPlayer(viewPos);

    float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
    vec3 nWorldPos = normalize(worldPos);
    nWorldPos.y += nWorldPos.x * END_BLACK_HOLE_ANGLE;

    vec3 worldLightVec = mat3(gbufferModelViewInverse) * normalize(sunVec * 10000.0);
    worldLightVec.xz *= 32.0;

    float cloudTop = END_DISK_HEIGHT + END_DISK_THICKNESS * 10.0;
    float lowerPlane = (END_DISK_HEIGHT - cameraPosition.y) / nWorldPos.y;
    float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
    float minDist = max(min(lowerPlane, upperPlane), 0.0);
    float maxDist = max(lowerPlane, upperPlane);

    float planeDifference = maxDist - minDist;
    float rayLength = END_DISK_THICKNESS * 6.0;
    rayLength /= nWorldPos.y * nWorldPos.y * 6.0 + 1.0;
    float nearSampleBoost = clamp01(1.0 - minDist / 384.0);
    rayLength *= mix(1.0, 0.5, nearSampleBoost);

    vec3 startPos = cameraPosition + minDist * nWorldPos;
    vec3 sampleStep = nWorldPos * rayLength;
    int sampleCount = int(min(planeDifference / rayLength, mix(64.0, 96.0, nearSampleBoost)) + dither);

    if (maxDist < 0.0 || sampleCount <= 0) return;

    float cloud = 0.0;
    float cloudAlpha = 0.0;
    float cloudLighting = 0.0;

    float halfVoLSqrt = VoS * 0.5 + 0.5;
    float scattering = pow4(pow2(halfVoLSqrt));

    vec3 rayPos = startPos + sampleStep * dither;
    float maxDepth = currentDepth;
    float minimalNoise = 0.25 + dither * 0.25;
    float sampleTotalLength = minDist + rayLength * dither;
    float lViewPos = length(viewPos);
    vec2 wind = vec2(frameTimeCounter * 0.005, sin(frameTimeCounter * 0.1) * 0.01) * 0.1;

    for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
        if (0.99 < cloudAlpha || (lViewPos < sampleTotalLength && z < 1.0)) break;

        vec3 sampleWorldPos = rayPos - cameraPosition;

        float shadow1 = 1.0;
        #if SHADOW_QUALITY > -1
            vec3 shadowPos = PlayerToShadow(sampleWorldPos);
            float distb = length(shadowPos.xy);
            float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
            shadowPos.xy /= distortFactor;
            shadowPos.z *= 0.2;
            shadowPos = shadowPos * 0.5 + 0.5;
            if (clamp(shadowPos.x, 0.0, 1.0) == shadowPos.x &&
                clamp(shadowPos.y, 0.0, 1.0) == shadowPos.y &&
                clamp(shadowPos.z, 0.0, 1.0) == shadowPos.z) {
                vec2 shadowTexel = vec2(1.5 / float(shadowMapResolution));
                shadow1  = shadow2D(shadowtex1, shadowPos).x;
                shadow1 += shadow2D(shadowtex1, vec3(shadowPos.xy + vec2( shadowTexel.x, 0.0), shadowPos.z)).x;
                shadow1 += shadow2D(shadowtex1, vec3(shadowPos.xy + vec2(-shadowTexel.x, 0.0), shadowPos.z)).x;
                shadow1 += shadow2D(shadowtex1, vec3(shadowPos.xy + vec2(0.0,  shadowTexel.y), shadowPos.z)).x;
                shadow1 += shadow2D(shadowtex1, vec3(shadowPos.xy + vec2(0.0, -shadowTexel.y), shadowPos.z)).x;
                shadow1 *= 0.2;
            }
        #endif

        float noise = 0.0;
        float lightingNoise = 0.0;
        float rayDistance = length(sampleWorldPos.xz) * 0.1;
        float attenuation = smoothstep(END_DISK_HEIGHT, cloudTop, rayPos.y);

        epGetEndCloudSample(rayPos.xz, wind, attenuation, noise);
        epGetEndCloudSample(rayPos.xz + worldLightVec.xz, wind, attenuation + worldLightVec.y * 0.15, lightingNoise);

        float sampleLighting = 0.05 + clamp(noise - lightingNoise * (0.9 - scattering * 0.15), 0.0, 0.95) * (1.5 + scattering);
        sampleLighting *= 1.0 - noise * 0.75;
        sampleLighting = clamp(sampleLighting, 0.0, 1.0);

        cloudLighting = mix(cloudLighting, sampleLighting, clamp01(noise * (1.0 - cloud * cloud)));
        cloud = mix(cloud, 1.0, clamp01(noise));
        noise *= pow4(pow2(smoothstep(4000.0, 8.0, rayDistance)));
        cloudAlpha = mix(cloudAlpha, 1.0, clamp01(noise));

        if (noise > minimalNoise && currentDepth == maxDepth) {
            currentDepth = sampleTotalLength;
        }
    }

    vec3 diskLightSqrt = vec3(END_BHOLE_LIGHT_R, END_BHOLE_LIGHT_G, END_BHOLE_LIGHT_B) * END_BHOLE_LIGHT_I;
    vec3 endLightCol = diskLightSqrt * diskLightSqrt;
    vec3 cloudColor = vec3(0.95, 1.0, 0.5) * endLightCol;
    cloudColor *= cloudLighting * 0.35;

    vc = vec4(cloudColor, cloudAlpha * END_DISK_OPACITY) * visibility;
}

#endif

#endif
