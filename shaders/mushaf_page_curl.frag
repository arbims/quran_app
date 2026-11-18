#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uCurlPos;
uniform vec2 uCurlDir;
uniform float uRadius;
uniform float uShadowWidth;
uniform float uBackOpacity;
uniform float uReverse;

uniform sampler2D uCurrentPage;
uniform sampler2D uNextPage;

out vec4 fragColor;

const float M_PI = 3.14159265359;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    if (uReverse > 0.5) {
        uv.x = 1.0 - uv.x;
    }

    vec2 dir = normalize(uCurlDir);
    if (uReverse > 0.5) {
        dir.x = -dir.x;
    }

    vec2 curlPos = uCurlPos;
    if (uReverse > 0.5) {
        curlPos.x = 1.0 - curlPos.x;
    }

    vec2 origin;
    if (abs(dir.x) > 0.001) {
        origin = curlPos - dir * (curlPos.x / dir.x);
    } else {
        origin = vec2(0.0, curlPos.y);
    }
    origin = clamp(origin, 0.0, 1.0);

    vec2 fragVec = uv - origin;
    float fragDist = dot(fragVec, dir);
    vec2 curlVec = curlPos - origin;
    float curlDist = dot(curlVec, dir);
    float d = fragDist - curlDist;
    float r = uRadius;
    vec2 linePoint = uv - d * dir;

    vec4 color;
    float shadowFactor = 1.0;

    if (d > r) {
        vec2 sampleUV = uv;
        if (uReverse > 0.5) {
            sampleUV.x = 1.0 - sampleUV.x;
        }
        color = texture(uNextPage, sampleUV);
        float shadowDist = d - r;
        if (shadowDist < uShadowWidth * r * 5.0) {
            shadowFactor = mix(0.62, 1.0, clamp(shadowDist / (uShadowWidth * r * 5.0), 0.0, 1.0));
        }
    } else if (d > 0.0 && r > 0.0) {
        float theta = asin(clamp(d / r, -1.0, 1.0));
        float d1 = theta * r;
        vec2 p1 = linePoint + dir * d1;
        float d2 = (M_PI - theta) * r;
        vec2 p2 = linePoint + dir * d2;

        vec2 p1Sample = p1;
        vec2 p2Sample = p2;
        if (uReverse > 0.5) {
            p1Sample.x = 1.0 - p1Sample.x;
            p2Sample.x = 1.0 - p2Sample.x;
        }

        if (p2.x >= 0.0 && p2.x <= 1.0 && p2.y >= 0.0 && p2.y <= 1.0) {
            vec2 backUV = vec2(1.0 - p2Sample.x, p2Sample.y);
            vec4 backFace = texture(uCurrentPage, backUV);
            vec4 bleed = texture(uNextPage, p2Sample);
            float vellum = mix(0.38, 0.72, uBackOpacity);
            color = mix(bleed, backFace, vellum);
            float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            color.rgb = mix(color.rgb, vec3(grey), uBackOpacity * 0.18);
            shadowFactor = mix(0.78, 1.0, clamp(theta / (M_PI * 0.5), 0.0, 1.0));
        } else if (p1.x >= 0.0 && p1.x <= 1.0 && p1.y >= 0.0 && p1.y <= 1.0) {
            color = texture(uCurrentPage, p1Sample);
            shadowFactor = mix(0.88, 1.0, clamp(theta / (M_PI * 0.5), 0.0, 1.0));
        } else {
            vec2 sampleUV = uv;
            if (uReverse > 0.5) {
                sampleUV.x = 1.0 - sampleUV.x;
            }
            color = texture(uNextPage, sampleUV);
            float shadowDist = r - d;
            shadowFactor = mix(0.65, 1.0, clamp(shadowDist / (uShadowWidth * r * 5.0), 0.0, 1.0));
        }
    } else {
        if (r > 0.0) {
            float unrollDist = M_PI * r - d;
            vec2 p = linePoint + dir * unrollDist;
            vec2 pSample = p;
            if (uReverse > 0.5) {
                pSample.x = 1.0 - pSample.x;
            }
            if (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) {
                vec2 backUV = vec2(1.0 - pSample.x, pSample.y);
                vec4 backFace = texture(uCurrentPage, backUV);
                vec4 bleed = texture(uNextPage, pSample);
                float vellum = mix(0.35, 0.68, uBackOpacity);
                color = mix(bleed, backFace, vellum);
                float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
                color.rgb = mix(color.rgb, vec3(grey), uBackOpacity * 0.15);
                shadowFactor = mix(0.58, 1.0, clamp(-d / (r * 2.5), 0.0, 1.0));
            } else {
                vec2 sampleUV = uv;
                if (uReverse > 0.5) {
                    sampleUV.x = 1.0 - sampleUV.x;
                }
                color = texture(uCurrentPage, sampleUV);
            }
        } else {
            vec2 sampleUV = uv;
            if (uReverse > 0.5) {
                sampleUV.x = 1.0 - sampleUV.x;
            }
            color = texture(uCurrentPage, sampleUV);
        }
    }

    color.rgb *= shadowFactor;
    fragColor = color;
}
