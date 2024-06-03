# base91-luau

An implementation of Base91 in Luau. As the primary consumer of Luau is Roblox,
this module uses apostrophes (`'`) instead of quotation marks (`"`) for the
output.

Four functions are returned from the [main module](src/init.lua):

- `encodeString`
- `decodeString`
- `encodeBytes`
- `decodeBytes`
- `encodeBuffer`
- `decodeBuffer`

These functions are documented below. They are also documented more thoroughly within the module itself.

---

```luau
encodeString(input: string): string
```

Takes a string and applies base91 encoding to it.

```luau
decodeString(input: string): string
```

Takes a base91 encoded string and decodes it.

```luau
encodeBytes(input: {number}): {number}
```

Takes an array of bytes and returns them as a base91 encoded sequence.
These bytes should be 8 bits.

```luau
decodeBytes(input: {number}): {number}
```

Takes base91 encoded sequence of bytes and decodes them. The bytes should be
8 bits.

```luau
encodeBuffer(input: buffer, skipTruncating: boolean?): buffer
```

Takes a buffer and returns a base91 encoded version of it.

If `skipTruncating` is `true`, the returned buffer will be trimmed to be exactly the length of the output. The default value for `skipTruncating` is `true`.

```luau
decodeBuffer(input: buffer, skipTruncating: boolean?): buffer
```

Takes a base91 encoded buffer and returns it decoded.

If `skipTruncating` is `true`, the returned buffer will be trimmed to be exactly the length of the output. The default value for `skipTruncating` is `true`.
