# base91-luau

An implementation of Base91 in Luau. As the primary consumer of Luau is Roblox,
this module uses apostrophes (`'`) instead of quotation marks (`"`) for the
output.

Four functions are returned from the [main module](src/init.lua):

- `encodeString`
- `decodeString`
- `encodeBytes`
- `decodeBytes`

These functions are documented below.

--- 

```
encodeString(input: string): string
```

Takes a string and applies base91 encoding to it.

```
decodeString(input: string): string
```

Takes a base91 encoded string and decodes it.

```
encodeBytes(input: {number}): {number}
```

Takes an array of bytes and returns them as a base91 encoded sequence.
These bytes should be 8 bits.

```
decodeBytes(input: {number}): {number}
```
Takes base91 encoded sequence of bytes and decodes them. The bytes should be
8 bits.
