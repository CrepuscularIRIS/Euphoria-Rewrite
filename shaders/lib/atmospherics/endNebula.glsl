#ifndef END_NEBULA_GLSL
#define END_NEBULA_GLSL

// ---- Solas-like End Nebula + Black Hole + Void Clouds for Euphoria-Rewrite --
// Nebula+Black Hole ported from Solas Shader V3.3 by Septonious
//   shaders/lib/atmosphere/endNebula.glsl
// Void Clouds: original, uses same bHoleCoord space as Solas disk
//
// Adaptations for EP:
//   fmix(a,b,t) → mix(a, b, clamp01(t))     (EP has clamp01, not fmix)
//   pow32/pow24/pow20 → pow() built-in        (EP has pow2/3/4 only)
//   endLightCol → epBHLightCol                (own RGB/I settings)
//   endNebulaColFirst/Second → epNebulaCol*   (own RGB/I settings)
//   sunPathRotation → END_DISK_TILT_FACTOR    (GUI-tweakable tilt constant)

#include "/lib/shaderSettings/endNebula.glsl"

// ---- Color derived values (mirrors Solas common.glsl pattern) ---------------
// R/G/B are float 0.0-1.0 (EP convention). sqrt-gamma encoding: color = (rgb * I)^2.
vec3 epBHLightColSqrt   = vec3(END_BHOLE_LIGHT_R, END_BHOLE_LIGHT_G, END_BHOLE_LIGHT_B) * END_BHOLE_LIGHT_I;
vec3 epBHLightCol       = epBHLightColSqrt * epBHLightColSqrt;

vec3 epEndAmbientColSqrt = vec3(END_AMBIENT_R, END_AMBIENT_G, END_AMBIENT_B) * END_AMBIENT_I;
vec3 epEndAmbientCol     = epEndAmbientColSqrt * epEndAmbientColSqrt;

vec3 epNebulaCol1Sqrt   = vec3(NEBULA_END_FIRST_R,  NEBULA_END_FIRST_G,  NEBULA_END_FIRST_B)  * NEBULA_END_FIRST_I;
vec3 epNebulaCol1       = epNebulaCol1Sqrt  * epNebulaCol1Sqrt;

vec3 epNebulaCol2Sqrt   = vec3(NEBULA_END_SECOND_R, NEBULA_END_SECOND_G, NEBULA_END_SECOND_B) * NEBULA_END_SECOND_I;
vec3 epNebulaCol2       = epNebulaCol2Sqrt * epNebulaCol2Sqrt;

vec4 sampleSolasEndNoise(vec2 coord) {
    return texture2DLod(solasEndNoiseTex, coord, 0.0);
}

// ---- 3-sample noise function (identical to Solas) ---------------------------
void sampleEndNebulaNoise(vec2 coord, inout float colorMixer, inout float noise) {
    colorMixer  = sampleSolasEndNoise(coord * 0.25).r;
    noise       = sampleSolasEndNoise(coord * 0.50).r;
    noise      *= colorMixer;
    noise      *= sampleSolasEndNoise(coord * 0.125).r;
    noise      *= 2.0 + noise * 20.0;
}

// ---- Spiral warp (identical to Solas) ----------------------------------------
// whirl = -15, arms = 15 are Solas defaults — do not change without matching nebula coord.
float endSpiralWarping(vec2 coord) {
    const float whirl = -15.0;
    const float arms  =  15.0;
    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.1,
                 sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow(1.0 - coord.y, 8.0) * 24.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;
    return clamp(spiral * 0.025, 0.0, 1.0);
}

// ---- 2D rotation matrix (identical to Solas) ---------------------------------
vec2 endRotate2D(vec2 p, float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c) * p;
}

// ---- Main draw function ------------------------------------------------------
// worldDir : world-space view direction (mat3(gbufferModelViewInverse) * nViewPos)
// VoS      : dot(nViewPos, sunVec) — sunVec is the black hole's sky anchor in End
// VoU      : dot(nViewPos, upVec)
void DrawEndNebula(inout vec3 color, vec3 worldDir, float VoU, float VoS) {
    float absVoU      = abs(VoU);
    float sqrtAbsVoU  = sqrt(absVoU);
    float blackHoleSize = END_BLACK_HOLE_SIZE;
    float VoSBH       = clamp01(VoS);

    // ---- Black hole mask ---------------------------------------------------
    // Solas: pow(pow4(pow32(VoS)), blackHoleSize) = VoS^(128*blackHoleSize)
    // VoS^2 is always ≥ 0; chaining pow4 gives VoS^128 without undefined pow(neg).
    float vs2   = VoSBH * VoSBH;          // Forward-hemisphere only to avoid a mirrored second core
    float vs128 = pow4(pow4(pow4(vs2)));  // VoS^128 (always ≥ 0)
    float hole  = pow(vs128, blackHoleSize);
    float gravityLens = hole;
    hole = pow2(pow2(hole));             // Solas's extra squarings for sharper edge

    // ---- Black hole position / disk coordinates ----------------------------
    vec3  wSunVec    = mat3(gbufferModelViewInverse) * sunVec;
    vec2  sunCoord   = wSunVec.xz / (wSunVec.y + length(wSunVec));
    vec2  bHoleCoord = worldDir.xz / (length(worldDir) + worldDir.y) - sunCoord;
          bHoleCoord.y -= bHoleCoord.x * END_BLACK_HOLE_ANGLE;

    float warping     = endSpiralWarping(bHoleCoord);
    bHoleCoord.x *= 0.75 - absVoU * 0.25;          // Solas horizontal squeeze
    bHoleCoord.y *= 5.0;                            // Solas vertical stretch
    bHoleCoord.y += pow2(bHoleCoord.x * 2.25) * sqrtAbsVoU;  // Solas curvature

    // ---- Nebula sample coordinates -----------------------------------------
    vec2 nebulaCoord  = worldDir.xz / (length(worldDir.y) + length(worldDir));
         nebulaCoord += warping * gravityLens;       // spiral pull toward black hole
         nebulaCoord += cameraPosition.xz * 0.0001; // slight position drift

    float nebulaNoise = 0.0, nebulaColorMixer = 0.0;
    sampleEndNebulaNoise(nebulaCoord, nebulaColorMixer, nebulaNoise);
    nebulaColorMixer = pow3(nebulaColorMixer) * 4.5; // Solas's exact shaping

    // ---- Nebula visibility (Solas formula) ---------------------------------
    // Attenuates nebula near the black hole core and boosts it on the disk ring.
    float nebulaVis      = (0.175 - VoSBH * VoSBH * VoSBH * 0.175)
                         + pow(VoSBH, 20.0) * 0.425;

    // ---- Nebula color composition ------------------------------------------
    vec3 blackHoleAccent = vec3(5.6, 3.2, 0.7) * epBHLightCol; // Solas's exact BH glow
    vec3 nebula = mix(epNebulaCol1, epNebulaCol2, clamp01(nebulaColorMixer))
                  * nebulaNoise * nebulaNoise * nebulaVis;
         nebula *= 1.0 + blackHoleAccent * pow(VoSBH, 24.0) * 0.25;
         nebula *= max(1.0 - pow(VoSBH, 32.0), 0.0);
         nebula *= length(nebula) * END_NEBULA_BRIGHTNESS;

    #ifdef END_NEBULA
        color += nebula;
    #endif

    // ---- End Void Clouds (Solas gravity-lens cloud layer) ------------------
    // Projected in bHoleCoord space — "same height" as the accretion disk.
    // gravityLens warps cloud coords toward the black hole = "vision effect".
    #ifdef END_VOID_CLOUDS
    {
        vec2 cloudCoord  = worldDir.xz / (length(worldDir) + abs(worldDir.y) + 0.001);
             cloudCoord += warping * gravityLens * END_CLOUD_WARP;
             cloudCoord += cameraPosition.xz * 0.00012;

        float cn1 = sampleSolasEndNoise(cloudCoord * 0.30).r;
        float cn2 = sampleSolasEndNoise(cloudCoord * 0.75 + vec2(0.31, 0.71)).r;
        float cloud  = cn1 * cn2;
              cloud  = cloud * cloud * END_CLOUD_DENSITY * 3.0;
              cloud *= max(1.0 - pow(VoSBH, 16.0), 0.0); // clear at BH core
              cloud *= 1.0 - pow(absVoU, 1.5);               // clear near zenith/nadir

        vec3 cloudColor = epBHLightCol * mix(0.25, 0.45, clamp01(cn1));
             cloudColor *= 1.0 + blackHoleAccent * pow(VoSBH, 12.0) * 0.4;
             cloudColor *= cloud * END_CLOUD_BRIGHTNESS;
        color += cloudColor;
    }
    #endif // END_VOID_CLOUDS

    // ---- Black hole --------------------------------------------------------
    #ifdef END_BLACK_HOLE
    float photonRing  = pow2(hole * 3.0);
          photonRing *= float(photonRing > 0.2) * (1.0 - 6.0 * hole) * 64.0;
          photonRing  = max(photonRing, 0.0);
    hole = clamp(hole * 8.0, 0.0, 1.0);

    // Accretion torus — shape from Solas torus formula.
    // END_DISK_TILT_FACTOR default = 1+(180-abs(-70))/8 = 14.75 (Solas SUN_ANGLE_END=-70)
    float torus = 1.0 - clamp(length(bHoleCoord), 0.0, 1.0);
    float torusTilt = 1.0 + (END_DISK_TILT_FACTOR - 1.0) * (0.5 + 0.5 * sqrtAbsVoU);
          torus = pow(pow(torus * torus, torusTilt),
                      sqrt(blackHoleSize) * 1.5);

    // Disk noise (animated rotation — Solas: frameTimeCounter * 0.025)
    vec2 noiseCoord  = bHoleCoord - hole * hole;
         noiseCoord  = endRotate2D(noiseCoord, 3.14159265);
         noiseCoord -= vec2(frameTimeCounter * 0.025, 0.0);
         noiseCoord.y *= 0.33;
         noiseCoord   *= 2.0;
    float bhNoise = sampleSolasEndNoise(noiseCoord).r;

    // Solas's exact black hole color composition:
    color += mix(blackHoleAccent, vec3(4.0 + hole * hole * 2.0), hole * hole)
             * hole * hole * 3.0 * bhNoise;
    color *= 1.0 - hole;                // void/absorption masking
    color += vec3(photonRing);          // bright photon ring rim
    color += mix(blackHoleAccent, vec3(2.0 + torus * 6.0), pow(torus, 0.33))
             * torus * pow2(1.0 - torus * 0.65) * bhNoise * 3.0;
    #endif // END_BLACK_HOLE
}

#endif // END_NEBULA_GLSL
