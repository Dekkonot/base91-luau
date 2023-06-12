--!strict
local base91 = require("src/init")

local TEST_STRINGS: { { string } } = table.freeze({
	{ "Hello, World!", ">OwJh>}AQ;r@@Y?F" },
	{ "", "" },
	{ "f", "LB" },
	{ "fo", "drD" },
	{ "foo", "dr.J" },
	{ "foob", "dr/2Y" },
	{ "fooba", "dr/2s)A" },
	{ "foobar", "dr/2s)uC" },
	{ "A\0B", "%A]C" },
	{ "A\n\t\v", "=cc)C" },
	{ "☺☻", "A+l9tRLE" },
	{
		-- No rights reserved whatsoever on the contents of the next string
		"Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads",
		"riM=Q[yCd#}uq9:mu'I80oZBHeq@]0m$'u|WGmgP>vG:1p;RqSO9<mIEZ2Q[}AcHd,EIlT8&ZEkLUa^gp@((uS309M1oyqwJ,Wzv;R90{BHnoM_1:WzvLR4tJF8j44zgc,.688O;4^7jXBTKu)mCmU40!5Qn9o(gK:bT:HAww^'pxoIJE<S$;R2u_XUoQPYhcH?`6U)/ZQmLprzIO[}A%gv;UCS$ztf^rmWd]:/Wzv;R#(BQ{iKBnGB*(*1Tq3U?5jw5>vH:[pwSZ6axcLkre3@[+0lTr#x8Xii4G<d,=/;Ro4O98ju'L^apr5zg<W]{LRa.$LGmRBJg<WweW$`+[80oEUzIq/rN$F(&9.cj>W_1fHe0m$@+sjlLAEefZf1RrUEv4^7jXB&=/W9*7%ztsQ_o)z`'SiSggZ5=SC4!i.hQ6PhtGf7=!e7Ra&=E<oTPh+z;_6y6c.hQmLIENKg,J`ASr#8^;m+XZ2e,}A%gt)BZL%L)9M;m_k9KL,.e<ur&9.`o1,>vi>6YaUXtgQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.$LgLTP01:WmeKUM<NQ|i?ieZ7=TXi#ztz^VowaU=,W!{6U6tFF8j.IzIX<wCS$4O#D8j'yzIL:oCH%=#N.cjYBJg,WSk$y+@mBQnYP>vt)uCI!Gv<b?WqM=Cp@GkxSq3nuPn#o=Cq/UCH%CvlE%ZEU^I;WMC}!20BQ;mYdjHu)yC>M^,g^apoM=Cu)&e#F10},kLfrLg,W.eaU!0DyWiIjeZh,DZ<RYzwP!D`qe3@[N1$F(&ax0ou'gQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.TiLn9oW3l`|L3$PzHycLIE{f,Wwe#F!&G97DLr=Cq/UC%TBv58jL;'08Km3oJ2T9JTrULfMbikxo+fTf=/2$f%hQFlTBJg_<k6,7B9pEimKB9<|<(*8y7&9.`o1,>vi>6YaURcDm8j_k^IV/1;;RXtP^'pTBV<1]_YM%9t,^Xiy2`'UiWPgZe,%t2$60{BTj_%$J%*0emT}+eFMoDEf<c",
	},
})

local function time<R, P...>(func: (P...) -> R, ...: P...): (number, R)
	local startTime = os.clock()
	local result = func(...)
	return os.clock() - startTime, result
end

local ESCAPE_SEQUENCES = {
	["\a"] = "\\a",
	["\b"] = "\\b",
	["\t"] = "\\t",
	["\n"] = "\\n",
	["\v"] = "\\v",
	["\f"] = "\\f",
	["\r"] = "\\r",
}

local function escapeChar(char: string): string
	if ESCAPE_SEQUENCES[char] then
		return ESCAPE_SEQUENCES[char]
	else
		local codepoint = utf8.codepoint(char)
		if codepoint <= 31 or codepoint >= 127 then
			return "\\" .. codepoint
		else
			return char
		end
	end
end

for n, test in TEST_STRINGS do
	if #test ~= 2 then
		error(`test #{n} had {#test} values when expecting 2`)
	end
	local inputBytes = { string.byte(test[1], 1, -1) }
	local outputBytes = { string.byte(test[2], 1, -1) }

	local byteEncodeTime, byteEncodeResult = time(base91.encodeBytes, inputBytes)
	local stringEncodeTime, stringEncodeResult = time(base91.encodeString, test[1])

	local byteDecodeTime, byteDecodeResult = time(base91.decodeBytes, outputBytes)
	local stringDecodeTime, stringDecodeResult = time(base91.decodeString, test[2])

	if stringEncodeResult == test[2] then
		print(`Test #{n} string encode passed -- took {stringEncodeTime}s`)
	else
		local printableResult = string.gsub(stringEncodeResult, utf8.charpattern, escapeChar)
		local printableExpected = string.gsub(test[2], utf8.charpattern, escapeChar)
		error(`Test #{n} string encode failed\nExpected:\n  {printableExpected}\nGot:\n  {printableResult}`)
	end

	if stringDecodeResult == test[1] then
		print(`Test #{n} string decode passed -- took {stringDecodeTime}s`)
	else
		local printableResult = string.gsub(stringDecodeResult, utf8.charpattern, escapeChar)
		local printableExpected = string.gsub(test[1], utf8.charpattern, escapeChar)
		error(`Test #{n} string decode failed\nExpected:\n  {printableExpected}\nGot:\n  {printableResult}`)
	end

	for i, enByte in byteEncodeResult do
		if enByte ~= outputBytes[i] then
			error(
				`Test #{n} byte encode failed -- value differed at byte {i} (expected {outputBytes[i]}, got {enByte})`
			)
		end
	end
	print(`Test #{n} byte encode passed -- took {byteEncodeTime}s`)

	for i, deByte in byteDecodeResult do
		if deByte ~= inputBytes[i] then
			error(`Test #{n} byte decode failed -- value differed at byte {i} (expected {inputBytes[i]}, got {deByte})`)
		end
	end
	print(`Test #{n} byte encode passed -- took {byteDecodeTime}s`)
end
print()

local input = "dekkonot"
local last = input
local encodeStart = os.clock()
for _ = 1, 60 do
	last = base91.encodeString(last)
end
print(`Encoding stress test took {os.clock() - encodeStart}`)
local decodeStart = os.clock()
for _ = 1, 60 do
	last = base91.decodeString(last)
end
print(`Decoding stress test took {os.clock() - decodeStart}`)
assert(input == last, "cyclical encoding followed by cyclical decoding did not result in the same value")
