--!strict

type NoiseClass = {
	__index: NoiseClass,
	seed: number,
	perm: {number},
	new: (seed: number?) -> Noise,
	perlin2d: (self: Noise, x: number, y: number) -> number,
	fbm: (self: Noise, x: number, y: number, octaves: number?, lacunarity: number?, gain: number?) -> number,
	absPerlin: (self: Noise, x: number, y: number) -> number,
}

export type Noise = typeof(setmetatable({} :: {
	seed: number,
	perm: {number},
}, {} :: NoiseClass))

local Noise = {}
Noise.__index = Noise

local PERM = {
	151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
	140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
	247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
	57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
	74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
	60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
	65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
	200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
	52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
	207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
	119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
	129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
	218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
	81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
	184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
	222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
	151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
	140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
	247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
	57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
	74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
	60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
	65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
	200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
	52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
	207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
	119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
	129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
	218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
	81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
	184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
	222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
}

local GRAD: {{number}} = {
	{1, 1}, {-1, 1}, {1, -1}, {-1, -1},
	{1, 0}, {-1, 0}, {0, 1}, {0, -1},
}

local function fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(a: number, b: number, t: number): number
	return a + t * (b - a)
end

local function dot(gi: number, x: number, y: number): number
	local g = GRAD[gi % 8 + 1]
	return g[1] * x + g[2] * y
end

function Noise.new(seed: number?): Noise
	local self = setmetatable({}, Noise) :: any
	self.seed = seed or 0
	self.perm = table.clone(PERM)
	if self.seed ~= 0 then
		math.randomseed(self.seed)
		for i = #self.perm, 2, -1 do
			local j = math.random(1, i)
			self.perm[i], self.perm[j] = self.perm[j], self.perm[i]
		end
	end
	return self :: Noise
end

function Noise:perlin2d(x: number, y: number): number
	local X = (x // 1) % 256
	local Y = (y // 1) % 256
	x = x - (x // 1)
	y = y - (y // 1)
	local u = fade(x)
	local v = fade(y)
	local A = self.perm[X + 1] + Y
	local B = self.perm[X + 2] + Y
	return lerp(
		lerp(dot(self.perm[A + 1], x, y), dot(self.perm[B + 1], x - 1, y), u),
		lerp(dot(self.perm[A + 2], x, y - 1), dot(self.perm[B + 2], x - 1, y - 1), u),
		v
	)
end

function Noise:fbm(x: number, y: number, octaves: number?, lacunarity: number?, gain: number?): number
	const octaves = octaves or 4
	const lacunarity = lacunarity or 2.0
	const gain = gain or 0.5
	local value = 0
	local amplitude = 1
	local frequency = 1
	local maxValue = 0
	for _ = 1, octaves do
		value += amplitude * self:perlin2d(x * frequency, y * frequency)
		maxValue += amplitude
		amplitude *= gain
		frequency *= lacunarity
	end
	return value / maxValue
end

function Noise:absPerlin(x: number, y: number): number
	return math.abs(self:perlin2d(x, y))
end

return Noise
