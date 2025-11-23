unit module Net::Nostr::Types;

#| Subset for 32-byte hex-encoded string (64 characters)
#| Validates that the string consists of exactly 64 lowercase hex digits
my subset HexKey of Str is export where * ~~ /^ <[0..9a..f]> ** 64 $/;

#| 64-byte hex-encoded string (128 characters) - for Signatures
my subset HexSignature of Str is export where * ~~ /^ <[0..9a..f]> ** 128 $/;

#| Unix Timestamp (non-negative integer)
my subset Timestamp of Int is export where * >= 0;

#| Event Kind (non-negative integer)
my subset Kind of Int is export where * >= 0;

#| A single tag is a list of strings (e.g. ["e", "event_id"])
#| Validates that it is an Array and all elements are Strings
my subset Tag of Array is export where { .all ~~ Str };

#| List of tags (e.g. [ ["e", "..."], ["p", "..."] ])
#| Validates that it is an Array and all elements are Tags
my subset Tags of Array is export where { .all ~~ Tag };
