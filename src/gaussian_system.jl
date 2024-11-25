## Agent
struct NoAgent <: Agent end
(c::NoAgent)(s) = nothing
Distributions.pdf(c::NoAgent, s, x) = 1.0

## Environment
struct SimpleGaussian <: Environment end
(env::SimpleGaussian)(s, a) = s
Ps(env::SimpleGaussian) = Normal()

## Sensor
struct IdealSensor <: Sensor end

(sensor::IdealSensor)(s) = s
(sensor::IdealSensor)(s, x) = sensor(s)

Distributions.pdf(sensor::IdealSensor, s, xₛ) = 1.0
