# nostraku API Reference

Complete API documentation for the nostraku library.

## Table of Contents

- [Net::Nostr::Types](#netnostrtypes)
- [Net::Nostr::Event](#netnostrevent)
- [Net::Nostr::Message](#netnostrmessage)
- [Net::Nostr::Signer](#netnostrsigner)

---

## Net::Nostr::Types

Type definitions for the Nostr protocol.

### Types

#### HexKey

```raku
my subset HexKey of Str where * ~~ /^ <[0..9a..f]> ** 64 $/
```

**Description:** A 32-byte hex-encoded string (64 characters). Used for public keys, private keys, and event IDs.

**Constraints:**
- Exactly 64 characters
- Only lowercase hexadecimal digits (0-9, a-f)

**Examples:**
```raku
my HexKey $pubkey = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
my HexKey $event-id = "a" x 64;  # Valid
my HexKey $invalid = "abc";      # Dies - too short
my HexKey $invalid2 = "G" x 64;  # Dies - invalid character
```

#### HexSignature

```raku
my subset HexSignature of Str where * ~~ /^ <[0..9a..f]> ** 128 $/
```

**Description:** A 64-byte hex-encoded string (128 characters). Used for Schnorr signatures.

**Constraints:**
- Exactly 128 characters
- Only lowercase hexadecimal digits (0-9, a-f)

**Examples:**
```raku
my HexSignature $sig = "a" x 128;  # Valid
my HexSignature $invalid = "abc";  # Dies - too short
```

#### Timestamp

```raku
my subset Timestamp of Int where * >= 0
```

**Description:** Unix timestamp (non-negative integer).

**Examples:**
```raku
my Timestamp $now = now.Int;
my Timestamp $past = 1234567890;
my Timestamp $invalid = -1;  # Dies - negative
```

#### Kind

```raku
my subset Kind of Int where * >= 0
```

**Description:** Event kind identifier (non-negative integer).

**Common Values:**
- 0 - Metadata
- 1 - Text note
- 2 - Recommend relay
- 3 - Contacts
- 4 - Encrypted direct messages
- 7 - Reaction

**Examples:**
```raku
my Kind $text-note = 1;
my Kind $metadata = 0;
my Kind $invalid = -1;  # Dies - negative
```

#### Tag

```raku
my subset Tag of Array where { .all ~~ Str }
```

**Description:** A single tag as an array of strings.

**Examples:**
```raku
my Tag $event-tag = ["e", "event_id_here"];
my Tag $pubkey-tag = ["p", "pubkey_here"];
my Tag $invalid = [1, 2, 3];  # Dies - not all strings
```

#### Tags

```raku
my subset Tags of Array where { .all ~~ Tag }
```

**Description:** Array of Tag objects.

**Examples:**
```raku
my Tags $tags = [
    ["e", "event_id"],
    ["p", "pubkey"],
    ["t", "nostr"],
];
```

---

## Net::Nostr::Event

Represents a Nostr event according to NIP-01.

### Constructor

```raku
my $event = Net::Nostr::Event.new(
    pubkey     => HexKey,      # Required
    created_at => Timestamp,   # Optional, defaults to now.Int
    kind       => Kind,        # Required
    tags       => Tags,        # Optional, defaults to []
    content    => Str,         # Optional, defaults to ""
)
```

### Attributes

#### id

```raku
has HexKey $.id is rw
```

**Description:** The event ID (32-byte SHA256 hash).

**Note:** Must be set after calculating with `calculate-id()`.

#### pubkey

```raku
has HexKey $.pubkey is required
```

**Description:** Public key of the event creator.

#### created_at

```raku
has Timestamp $.created_at is required = now.Int
```

**Description:** Unix timestamp when the event was created.

#### kind

```raku
has Kind $.kind is required
```

**Description:** Event kind identifier.

#### tags

```raku
has Tags $.tags is required = []
```

**Description:** Array of tags for event metadata.

#### content

```raku
has Str $.content is required = ""
```

**Description:** Event content (arbitrary string).

#### sig

```raku
has HexSignature $.sig is rw
```

**Description:** Schnorr signature of the event.

**Note:** Must be set after signing with `Net::Nostr::Signer`.

### Methods

#### serialize-for-id

```raku
method serialize-for-id() returns Str
```

**Description:** Serializes event data for ID calculation according to NIP-01.

**Returns:** JSON string in format: `[0, <pubkey>, <created_at>, <kind>, <tags>, <content>]`

**Example:**
```raku
my $serialized = $event.serialize-for-id();
say $serialized;  # [0,"pubkey",1234567890,1,[],"content"]
```

#### calculate-id

```raku
method calculate-id() returns Str
```

**Description:** Calculates the SHA256 hash of the serialized event.

**Returns:** 64-character hex string (event ID).

**Example:**
```raku
my $id = $event.calculate-id();
$event.id = $id;
```

#### verify-id

```raku
method verify-id() returns Bool
```

**Description:** Verifies that the current ID matches the calculated hash.

**Returns:** True if valid, False otherwise.

**Example:**
```raku
if $event.verify-id() {
    say "Event ID is valid";
} else {
    say "Event ID is invalid";
}
```

#### to-hash

```raku
method to-hash() returns Hash
```

**Description:** Converts the event to a Hash.

**Returns:** Hash with keys: id, pubkey, created_at, kind, tags, content, sig.

**Example:**
```raku
my %event = $event.to-hash();
say %event<id>;
```

#### to-json

```raku
method to-json() returns Str
```

**Description:** Converts the event to JSON string (compact format).

**Returns:** JSON string representation.

**Example:**
```raku
my $json = $event.to-json();
say $json;
```

---

## Net::Nostr::Message

Protocol message handling for WebSocket communication.

### Enum: MsgType

```raku
enum MsgType is export <EVENT REQ CLOSE>
```

**Values:**
- `EVENT` - For publishing events
- `REQ` - For requesting events
- `CLOSE` - For closing subscriptions

### Constructor

```raku
# Direct constructor (not recommended)
my $msg = Net::Nostr::Message.new(
    type => MsgType,           # Required
    event => Net::Nostr::Event,  # For EVENT type
    subscription-id => Str,      # For REQ/CLOSE types
    filters => Array,            # For REQ type
)
```

**Note:** Use factory methods instead: `new-event`, `new-req`, `new-close`.

### Attributes

#### type

```raku
has MsgType $.type is required
```

**Description:** Message type (EVENT, REQ, or CLOSE).

#### event

```raku
has Net::Nostr::Event $.event
```

**Description:** Event object (for EVENT messages).

#### subscription-id

```raku
has Str $.subscription-id
```

**Description:** Subscription identifier (for REQ/CLOSE messages).

#### filters

```raku
has Array $.filters
```

**Description:** Array of filter hashes (for REQ messages).

### Factory Methods

#### new-event

```raku
method new-event(Net::Nostr::Event $event)
```

**Description:** Creates an EVENT message.

**Parameters:**
- `$event` - The event to publish

**Returns:** Net::Nostr::Message instance

**Example:**
```raku
my $msg = Net::Nostr::Message.new-event($event);
```

#### new-req

```raku
method new-req(Str $sub-id, @filters)
```

**Description:** Creates a REQ message.

**Parameters:**
- `$sub-id` - Subscription identifier
- `@filters` - Array of filter hashes

**Filter Options:**
- `ids` - Array of event IDs
- `authors` - Array of author pubkeys
- `kinds` - Array of event kinds
- `#e` - Events referencing these event IDs
- `#p` - Events referencing these pubkeys
- `since` - Unix timestamp (events after)
- `until` - Unix timestamp (events before)
- `limit` - Maximum number of events

**Returns:** Net::Nostr::Message instance

**Example:**
```raku
my $msg = Net::Nostr::Message.new-req(
    "my-subscription",
    [
        { kinds => [1], limit => 10 },
        { authors => [$pubkey] },
    ]
);
```

#### new-close

```raku
method new-close(Str $sub-id)
```

**Description:** Creates a CLOSE message.

**Parameters:**
- `$sub-id` - Subscription identifier to close

**Returns:** Net::Nostr::Message instance

**Example:**
```raku
my $msg = Net::Nostr::Message.new-close("my-subscription");
```

### Methods

#### to-json

```raku
method to-json() returns Str
```

**Description:** Serializes the message to JSON for WebSocket transmission.

**Returns:** JSON string in appropriate format:
- EVENT: `["EVENT", <event_object>]`
- REQ: `["REQ", <sub_id>, <filter1>, <filter2>, ...]`
- CLOSE: `["CLOSE", <sub_id>]`

**Example:**
```raku
my $json = $msg.to-json();
websocket.send($json);
```

#### Str

```raku
method Str() returns Str
```

**Description:** Stringification overload (calls `to-json()`).

**Example:**
```raku
say $msg;  # Automatically calls to-json()
```

---

## Net::Nostr::Signer

Schnorr signature generation using secp256k1.

### Constructor

```raku
my $signer = Net::Nostr::Signer.new()
```

**Description:** Creates a new signer instance and initializes the secp256k1 context.

### Methods

#### sign

```raku
method sign(Str $id-hex, Str $privkey-hex --> Str)
```

**Description:** Signs a 32-byte message hash with a private key.

**Parameters:**
- `$id-hex` - Event ID (64-character hex string)
- `$privkey-hex` - Private key (64-character hex string)

**Returns:** 128-character hex string (Schnorr signature)

**Throws:** Dies if keypair creation or signing fails

**Example:**
```raku
my $signer = Net::Nostr::Signer.new;
my $signature = $signer.sign($event.id, $private-key);
$event.sig = $signature;
```

**Security Notes:**
- Never hardcode private keys
- Never commit private keys to version control
- Use secure storage for private keys
- Consider using environment variables or secure vaults

#### hex-to-carray

```raku
method hex-to-carray(Str $hex --> CArray[uint8])
```

**Description:** Converts a hex string to CArray[uint8] for native functions.

**Parameters:**
- `$hex` - Hexadecimal string

**Returns:** CArray[uint8]

**Note:** This is an internal utility method.

---

## Complete Usage Example

```raku
use Net::Nostr::Types;
use Net::Nostr::Event;
use Net::Nostr::Message;
use Net::Nostr::Signer;

# Define keys
my HexKey $pubkey = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
my HexKey $privkey = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";

# Create event
my $event = Net::Nostr::Event.new(
    pubkey     => $pubkey,
    created_at => now.Int,
    kind       => 1,
    tags       => [
        ["t", "nostraku"],
        ["t", "raku"],
    ],
    content    => "Hello from nostraku!",
);

# Calculate ID
$event.id = $event.calculate-id();

# Sign event
my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $privkey);

# Verify
say "Valid ID" if $event.verify-id();

# Create and send EVENT message
my $event-msg = Net::Nostr::Message.new-event($event);
say $event-msg.to-json();

# Create REQ message
my $req-msg = Net::Nostr::Message.new-req(
    "sub-1",
    [{ kinds => [1], authors => [$pubkey], limit => 10 }]
);
say $req-msg.to-json();

# Close subscription
my $close-msg = Net::Nostr::Message.new-close("sub-1");
say $close-msg.to-json();
```

---

## Error Handling

### Common Errors

#### Type Constraint Failures

```raku
# Invalid HexKey (too short)
my HexKey $key = "abc";  # Dies: Type check failed

# Invalid Kind (negative)
my Kind $kind = -1;  # Dies: Type check failed
```

#### Signing Errors

```raku
my $signer = Net::Nostr::Signer.new;
try {
    my $sig = $signer.sign($id, $invalid-key);
    CATCH {
        default { say "Signing failed: $_" }
    }
}
```

---

## Performance Considerations

- Event ID calculation uses SHA256 (fast)
- Signing operations use native secp256k1 library (fast)
- JSON serialization uses compact format (minimal overhead)
- Type constraints are validated at compile time when possible

---

## Thread Safety

The secp256k1 context is not thread-safe. If using multiple threads, create a separate `Net::Nostr::Signer` instance for each thread.

---

## Version Compatibility

This API documentation is for nostraku version 0.1.0.

For the latest API documentation, see the Pod6 documentation in the source code or visit the online documentation.
