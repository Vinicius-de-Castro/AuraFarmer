//
//  AuraShader.metal
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 11/08/26.
//

#include <metal_stdlib>
using namespace metal;

float random(float2 st) {
    return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453);
}

float2 randomGradient(float2 p) {
    float angle = random(p) * 6.28318530718;
    return float2(cos(angle), sin(angle));
}

// Este é um gerador de Perlin Noise, vindo de um dos papers mais influentes e premiados do século XX,
// Não me pergunte como funciona!!! Eu não faço ideia
float gradientNoise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);
    
    float2 g00 = randomGradient(i);
    float2 g10 = randomGradient(i + float2(1.0, 0.0));
    float2 g01 = randomGradient(i + float2(0.0, 1.0));
    float2 g11 = randomGradient(i + float2(1.0, 1.0));
    
    float n00 = dot(g00, f);
    float n10 = dot(g10, f - float2(1.0, 0.0));
    float n01 = dot(g01, f - float2(0.0, 1.0));
    float n11 = dot(g11, f - float2(1.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    float nx0 = mix(n00, n10, u.x);
    float nx1 = mix(n01, n11, u.x);
    return mix(nx0, nx1, u.y) * 0.5 + 0.5;
}

float generateNoise(
                    float2 st,
                    float value,
                    float amplitude,
                    float frequency,
                    float phase,
                    int octaves
                    ){
    for(int i = 0; i < octaves; i++) {
        st.y -= phase;
        value += amplitude * gradientNoise(st * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    value /= 2.0;
    
    return value;
}

[[ stitchable ]] half4 auraEffect(
                                  float2 position,
                                  half4 color,
                                  float2 size,
                                  float time,
                                  float aura) {
    
    float2 uv = position / size;
    float pi = 3.14159265359;
    
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 10.0;
    float phase = time * 0.2 + aura * 0.1;
    int octaves = 5;
    
    // Senos utilizados para gerar os ruídos
    float pulseSin = pow(sin(time/(pi*2)), 2);
    float fastPulseSin = pow(sin(10 * time/(pi*2)), 2);
    float auraSin = pow(sin(aura), 2);
    
    // Aura do bem
    float greenNoise = generateNoise(uv, value, amplitude/2, frequency * 2, phase * 3, octaves * 2);
    float blueNoise = generateNoise(uv, value, amplitude, frequency, phase, octaves);
    
    // Aura do anjo caído
    float redNoise = generateNoise(uv, value, amplitude * 2, frequency * 3, phase * 2, octaves * 2);
    float evilEnergy = min(1.0, pow(aura/67.0, 2.0));
    
    // "Pulsação" da aura do bem
    float auraOpacity = min(1.0, aura/10.0);
    float opacity = mix(0.08, mix(auraOpacity, auraSin, 0.5), pulseSin);
    
    
    float red = mix(0.0, redNoise, evilEnergy);
    float green = mix(greenNoise, blueNoise, (fastPulseSin * 0.5 + 0.5)) * 0.6;
    float blue = mix(blueNoise, 0.0, evilEnergy);

    return half4(red, green, blue, opacity);
}

[[ stitchable ]] float2 waveDistortion(float2 position, float time) {
    
    position.y += sin(position.x * 0.05 + time) + gradientNoise(position) * 10.0;
    position.x += gradientNoise(position) * 10.0;
    return position;
}
