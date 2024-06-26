--!strict
--!optimize 2
--!native
-- Pure Luau implementation of Base91 encoding and decoding.

-- This is the ratio used to allocate a table for the output of the functions
-- The actual ratio of expansion varies between 200% and 123% depending upon
-- the size of the input. This is a nice middleground to avoid
-- oversizing while still avoiding reallocations
local EXPECTED_EXPANSION = 1.2308

local CHAR_SET = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~']]
local encodeCharSet = table.create(90)
local decodeCharSet = table.create(90)

for i = 1, 91 do
	encodeCharSet[i - 1] = string.byte(CHAR_SET, i, i)
	decodeCharSet[string.byte(CHAR_SET, i, i)] = i - 1
end

local STRING_CHUNKS = table.create(5)

--- Takes an array of bytes and builds a string out of it.
--- Uses `4096` byte chunks to make the string, which ends up being very fast.
local function stringBuilder(input: { number }): string
	local inputLen = #input
	for i = 1, inputLen, 4096 do
		table.insert(STRING_CHUNKS, string.char(table.unpack(input, i, math.min(i + 4095, inputLen))))
	end
	local output = table.concat(STRING_CHUNKS)
	table.clear(STRING_CHUNKS)

	return output
end

--[=[
	Takes a buffer and returns its contents encoded into base91.

	For a function that operates on a string, see `encodeString`.
	For a function that operates on an array of bytes, see `encodeBytes`.

	@param input The buffer to encode as base91.
	@param skipTruncating Whether to skip trimming the buffer to be exactly the size of the output. Defaults to `false`.

	@return A buffer containing the contents of `input` after it has been encoded as base91.
]=]
local function encodeBuffer(input: buffer, skipTruncating: boolean?): buffer
	local output = buffer.create(buffer.len(input) * 2)
	local c = 0

	local accum = 0
	local bitC = 0

	for i = 0, buffer.len(input) - 1 do
		accum = bit32.bor(accum, bit32.lshift(buffer.readu8(input, i), bitC))
		bitC += 8
		if bitC > 13 then
			-- TL;DR: You can do 13 bits instead of 14 around half the time,
			-- which saves space at scale
			local codepoint = bit32.band(accum, 8191) -- 2^13 - 1
			if codepoint > 88 then
				accum = bit32.rshift(accum, 13)
				bitC -= 13
			else
				codepoint = bit32.band(accum, 16383) -- 2^14 - 1
				accum = bit32.rshift(accum, 14)
				bitC -= 14
			end
			-- Buffers write in little-endian, so we do this in reverse order
			buffer.writeu16(output, c, bit32.lshift(encodeCharSet[codepoint // 91], 8) + encodeCharSet[codepoint % 91])
			c += 2
		end
	end

	if bitC > 0 then
		buffer.writeu8(output, c, encodeCharSet[accum % 91])
		c += 1
		if bitC > 7 or accum > 90 then
			buffer.writeu8(output, c, encodeCharSet[accum // 91])
			c += 1
		end
	end

	if skipTruncating then
		return output
	else
		local truncated = buffer.create(c)
		buffer.copy(truncated, 0, output, 0, c)
		return truncated
	end
end

--[=[
	Takes a buffer and returns its contents decoded from base91 in a new
	buffer.

	For a function that operates on a string, see `decodeString`.
	For a function that operates on an array of bytes, see `decodeBytes`.

	@param input The buffer to decode from base91.
	@param skipTruncating Whether to skip trimming the buffer to be exactly the size of the output. Defaults to `false`.

	@return A buffer containing the contents of `input` that has been decoded from base91.
]=]
local function decodeBuffer(input: buffer, skipTruncating: boolean?): buffer
	local output = buffer.create(buffer.len(input) * 2)
	local c = 0

	local accum = 0
	local bitC = 0
	local codepoint = -1

	-- This implementation is not my favorite thing in the world
	-- but it is fast enough and don't care to do it any other way
	for i = 0, buffer.len(input) - 1 do
		local byte = buffer.readu8(input, i)
		-- This skips things like whitespace
		if not decodeCharSet[byte] then
			continue
		end
		if codepoint == -1 then
			codepoint = decodeCharSet[byte]
		else
			codepoint += decodeCharSet[byte] * 91
			accum = bit32.bor(accum, bit32.lshift(codepoint, bitC))
			if bit32.band(codepoint, 8191) > 88 then
				bitC += 13
			else
				bitC += 14
			end

			while bitC > 7 do
				buffer.writeu8(output, c, accum % 256)
				c += 1
				accum = bit32.rshift(accum, 8)
				bitC -= 8
			end
			codepoint = -1
		end
	end

	if codepoint ~= -1 then
		buffer.writeu8(output, c, bit32.bor(accum, bit32.lshift(codepoint, bitC)) % 256)
		c += 1
	end

	if skipTruncating then
		return output
	else
		local truncated = buffer.create(c)
		buffer.copy(truncated, 0, output, 0, c)
		return truncated
	end
end

--[=[
	Takes an array of bytes and returns its contents encoded into base91.

	For a function that operates on a string, see `encodeString`.
	For a function that operates on a buffer, see `encodeBuffer`.

	@param input The array to encode as base91.

	@return An array containing the contents of `input` after it has been encoded as base91.
]=]
local function encodeBytes(input: { number }): { number }
	local output = table.create(math.ceil(#input * EXPECTED_EXPANSION))
	local c = 1

	local accum = 0
	local bitC = 0

	for _, byte in input do
		accum = bit32.bor(accum, bit32.lshift(byte, bitC))
		bitC += 8
		if bitC > 13 then
			-- TL;DR: You can do 13 bits instead of 14 around half the time,
			-- which saves space at scale
			local codepoint = bit32.band(accum, 8191) -- 2^13 - 1
			if codepoint > 88 then
				accum = bit32.rshift(accum, 13)
				bitC -= 13
			else
				codepoint = bit32.band(accum, 16383) -- 2^14 - 1
				accum = bit32.rshift(accum, 14)
				bitC -= 14
			end
			output[c] = encodeCharSet[codepoint % 91]
			output[c + 1] = encodeCharSet[math.floor(codepoint / 91)]
			c += 2
		end
	end

	if bitC > 0 then
		output[c] = encodeCharSet[accum % 91]
		if bitC > 7 or accum > 90 then
			output[c + 1] = encodeCharSet[math.floor(accum / 91)]
		end
	end

	return output
end

--[=[
	Takes an array of bytes and returns its contents decoded from base91 in a
	new table.

	For a function that operates on a string, see `decodeString`.
	For a function that operates on a buffer, see `decodeBuffer`.

	@param input The bytes to decode from base91.

	@return An array containing the contents of `input` that has been decoded from base91.
]=]
local function decodeBytes(input: { number }): { number }
	local output = table.create(math.ceil(#input / EXPECTED_EXPANSION))
	local c = 1

	local accum = 0
	local bitC = 0
	local codepoint = -1

	-- This implementation is not my favorite thing in the world
	-- but it is fast enough and don't care to do it any other way
	for _, byte in input do
		-- This skips things like whitespace
		if not decodeCharSet[byte] then
			continue
		end
		if codepoint == -1 then
			codepoint = decodeCharSet[byte]
		else
			codepoint += decodeCharSet[byte] * 91
			accum = bit32.bor(accum, bit32.lshift(codepoint, bitC))
			if bit32.band(codepoint, 8191) > 88 then
				bitC = bitC + 13
			else
				bitC = bitC + 14
			end

			while bitC > 7 do
				output[c] = accum % 256
				c = c + 1
				accum = bit32.rshift(accum, 8)
				bitC = bitC - 8
			end
			codepoint = -1
		end
	end

	if codepoint ~= -1 then
		output[c] = bit32.bor(accum, bit32.lshift(codepoint, bitC)) % 256
	end

	return output
end

--[=[
	Takes a string and returns its contents encoded into base91.

	For a function that operates on an array of bytes, see `encodeBytes`.
	For a function that operates on a buffer, see `encodeBuffer`.

	@param input The string to encode as base91.

	@return A string containing the contents of `input` after it has been encoded as base91.
]=]
local function encodeString(input: string): string
	local output = table.create(#input * EXPECTED_EXPANSION)
	local c = 1

	local accum = 0
	local bitC = 0

	for i = 1, #input do
		accum = bit32.bor(accum, bit32.lshift(string.byte(input, i), bitC))
		bitC += 8
		if bitC > 13 then
			local codepoint = bit32.band(accum, 8191) -- 2^13 - 1
			if codepoint > 88 then
				accum = bit32.rshift(accum, 13)
				bitC -= 13
			else
				codepoint = bit32.band(accum, 16383) -- 2^14 - 1
				accum = bit32.rshift(accum, 14)
				bitC -= 14
			end
			output[c] = encodeCharSet[codepoint % 91]
			output[c + 1] = encodeCharSet[math.floor(codepoint / 91)]
			c += 2
		end
	end

	if bitC > 0 then
		output[c] = encodeCharSet[accum % 91]
		if bitC > 7 or accum > 90 then
			output[c + 1] = encodeCharSet[math.floor(accum / 91)]
		end
	end

	return stringBuilder(output)
end

--[=[
	Takes a string and returns its contents decoded from base91 as a string.

	For a function that operates on an array of bytes, see `decodeBytes`.
	For a function that operates on a buffer, see `decodeBuffer`.

	@param input The string to decode from base91.

	@return A string containing the contents of `input` that has been decoded from base91.
]=]
local function decodeString(input: string): string
	local output = table.create(math.ceil(#input / EXPECTED_EXPANSION))
	local c = 1

	local accum = 0
	local bitC = 0
	local codepoint = -1

	for i = 1, #input do
		local byte = string.byte(input, i)
		if not decodeCharSet[byte] then
			continue
		end
		if codepoint == -1 then
			codepoint = decodeCharSet[byte]
		else
			codepoint += decodeCharSet[byte] * 91
			accum = bit32.bor(accum, bit32.lshift(codepoint, bitC))
			if bit32.band(codepoint, 8191) > 88 then
				bitC = bitC + 13
			else
				bitC = bitC + 14
			end

			while bitC > 7 do
				output[c] = accum % 256
				c = c + 1
				accum = bit32.rshift(accum, 8)
				bitC = bitC - 8
			end
			codepoint = -1
		end
	end

	if codepoint ~= -1 then
		output[c] = bit32.bor(accum, bit32.lshift(codepoint, bitC)) % 256
	end

	return stringBuilder(output)
end

return table.freeze({
	encodeBuffer = encodeBuffer,
	decodeBuffer = decodeBuffer,

	encodeBytes = encodeBytes,
	decodeBytes = decodeBytes,

	encodeString = encodeString,
	decodeString = decodeString,
})
