#include ../includes/simplexNoise2d.glsl;

float getElevation(vec2 position) {
  float uPositionFrequency = 0.2;
  float uStrength = 2.0;
  float uWarpFrequency = 5.0;
  float uWarpStrength = 0.5;

  vec2 warpedPosition = position;
  warpedPosition += simplexNoise2d(warpedPosition * uWarpFrequency * uPositionFrequency) * uWarpStrength;
  
  float elevation = 0.0;
  float frequency = uPositionFrequency;
  float amplitude = 2.0;
  for (int i = 0; i < 3; i++) {
    elevation += simplexNoise2d(warpedPosition * frequency) / amplitude;
    frequency *= 2.0;
    amplitude *= 2.0;
  }

float elevationSign = sign(elevation);
  elevation = pow(abs(elevation), 2.0) * elevationSign;
  elevation *= uStrength;

  return elevation;
}

void main() {
  // neighbours positions
  float shift = 0.01;
  vec3 positionA = position + vec3(shift, 0.0, 0.0);
  vec3 positionB = position + vec3(0.0, 0.0, -shift);
  
  float elevation = getElevation(csm_Position.xz);
  
  csm_Position.y += elevation;
  positionA.y += getElevation(positionA.xz);
  positionB.y += getElevation(positionB.xz);

  // compute normal
  vec3 toA = normalize(positionA - csm_Position);
  vec3 toB = normalize(positionB - csm_Position);
  csm_Normal = normalize(cross(toA, toB));
}