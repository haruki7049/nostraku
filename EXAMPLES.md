# nostraku Examples

Practical examples for using the nostraku library.

## Table of Contents

- [Basic Event Creation](#basic-event-creation)
- [Event Signing](#event-signing)
- [Protocol Messages](#protocol-messages)
- [Working with Tags](#working-with-tags)
- [Event Verification](#event-verification)
- [Filter Queries](#filter-queries)
- [Complete WebSocket Example](#complete-websocket-example)
- [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)

---

## Basic Event Creation

### Creating a Simple Text Note

```raku
use Net::Nostr::Event;

my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,  # Text note
    tags       => [],
    content    => "Hello, Nostr!",
);

# Calculate event ID
$event.id = $event.calculate-id();

say "Event ID: $event.id()";
say $event.to-json();
```

### Creating a Metadata Event (Kind 0)

```raku
use Net::Nostr::Event;
use JSON::Fast;

my %metadata = 
    name => "Alice",
    about => "Raku developer interested in Nostr",
    picture => "https://example.com/avatar.jpg";

my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 0,  # Metadata
    tags       => [],
    content    => to-json(%metadata),
);

$event.id = $event.calculate-id();
```

---

## Event Signing

### Sign an Event with a Private Key

```raku
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Create event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Signed message",
);

# Calculate ID
$event.id = $event.calculate-id();

# Sign
my $signer = Net::Nostr::Signer.new;
my $privkey = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
$event.sig = $signer.sign($event.id, $privkey);

say "Signature: $event.sig()";
```

### Sign Multiple Events

```raku
use Net::Nostr::Event;
use Net::Nostr::Signer;

my $signer = Net::Nostr::Signer.new;
my $privkey = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
my $pubkey = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";

for 1..5 -> $i {
    my $event = Net::Nostr::Event.new(
        pubkey     => $pubkey,
        created_at => now.Int,
        kind       => 1,
        tags       => [],
        content    => "Message $i",
    );
    
    $event.id = $event.calculate-id();
    $event.sig = $signer.sign($event.id, $privkey);
    
    say "Event $i signed: $event.id()";
}
```

---

## Protocol Messages

### Publishing an Event (EVENT Message)

```raku
use Net::Nostr::Message;
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Create and sign event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Hello, relay!",
);
$event.id = $event.calculate-id();

my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $privkey);

# Create EVENT message
my $msg = Net::Nostr::Message.new-event($event);
say $msg.to-json();
# Output: ["EVENT",{"id":"...","pubkey":"...","created_at":...,"kind":1,"tags":[],"content":"Hello, relay!","sig":"..."}]
```

### Requesting Events (REQ Message)

```raku
use Net::Nostr::Message;

# Request all text notes
my $msg = Net::Nostr::Message.new-req(
    "subscription-1",
    [{ kinds => [1] }]
);
say $msg.to-json();

# Request recent events from specific author
my $msg2 = Net::Nostr::Message.new-req(
    "subscription-2",
    [{
        authors => ["f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320"],
        kinds => [1],
        limit => 20,
        since => (now - 86400).Int,  # Last 24 hours
    }]
);
say $msg2.to-json();
```

### Closing a Subscription (CLOSE Message)

```raku
use Net::Nostr::Message;

my $msg = Net::Nostr::Message.new-close("subscription-1");
say $msg.to-json();
# Output: ["CLOSE","subscription-1"]
```

---

## Working with Tags

### Event References (e-tags)

```raku
use Net::Nostr::Event;

# Reply to an event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [
        ["e", "parent_event_id_here", "", "root"],
        ["e", "replied_to_event_id", "", "reply"],
    ],
    content    => "This is a reply",
);
```

### Pubkey References (p-tags)

```raku
use Net::Nostr::Event;

# Mention users
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [
        ["p", "mentioned_user_pubkey_1"],
        ["p", "mentioned_user_pubkey_2"],
    ],
    content    => "Hello nostr:npub1... and nostr:npub2...",
);
```

### Hashtags (t-tags)

```raku
use Net::Nostr::Event;

my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [
        ["t", "nostr"],
        ["t", "raku"],
        ["t", "programming"],
    ],
    content    => "Learning #nostr with #raku #programming",
);
```

### Multiple Tag Types

```raku
use Net::Nostr::Event;

my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [
        ["e", "referenced_event_id"],
        ["p", "mentioned_pubkey"],
        ["t", "nostr"],
        ["t", "raku"],
    ],
    content    => "Complex event with multiple tags",
);
```

---

## Event Verification

### Verify Event ID

```raku
use Net::Nostr::Event;
use JSON::Fast;

# Receive event from relay (example)
my $received-json = '{"id":"abc123...","pubkey":"f835d6...","created_at":1234567890,"kind":1,"tags":[],"content":"Hello","sig":"def456..."}';
my %data = from-json($received-json);

my $event = Net::Nostr::Event.new(
    id         => %data<id>,
    pubkey     => %data<pubkey>,
    created_at => %data<created_at>,
    kind       => %data<kind>,
    tags       => %data<tags>,
    content    => %data<content>,
    sig        => %data<sig>,
);

if $event.verify-id() {
    say "✓ Event ID is valid";
} else {
    say "✗ Event ID is invalid!";
}
```

---

## Filter Queries

### Filter by Kind

```raku
use Net::Nostr::Message;

# Get text notes only
my $msg = Net::Nostr::Message.new-req(
    "text-notes",
    [{ kinds => [1] }]
);
```

### Filter by Author

```raku
use Net::Nostr::Message;

my $msg = Net::Nostr::Message.new-req(
    "alice-posts",
    [{
        authors => ["f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320"]
    }]
);
```

### Filter by Time Range

```raku
use Net::Nostr::Message;

# Events from the last hour
my $one-hour-ago = (now - 3600).Int;
my $msg = Net::Nostr::Message.new-req(
    "recent",
    [{
        since => $one-hour-ago,
        kinds => [1],
        limit => 50,
    }]
);
```

### Multiple Filters (OR Logic)

```raku
use Net::Nostr::Message;

my $msg = Net::Nostr::Message.new-req(
    "multiple-criteria",
    [
        # Filter 1: Text notes from Alice
        {
            authors => ["alice_pubkey"],
            kinds => [1],
        },
        # Filter 2: OR metadata from Bob
        {
            authors => ["bob_pubkey"],
            kinds => [0],
        },
    ]
);
```

### Complex Filter

```raku
use Net::Nostr::Message;

my $msg = Net::Nostr::Message.new-req(
    "complex-query",
    [{
        authors => [
            "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
            "another_pubkey_here",
        ],
        kinds => [1, 6, 7],  # Text notes, reposts, reactions
        "#t" => ["nostr", "raku"],  # With hashtags
        since => (now - 86400).Int,  # Last 24 hours
        limit => 100,
    }]
);
```

---

## Complete WebSocket Example

### Pseudo-code for WebSocket Client

```raku
use Net::Nostr::Event;
use Net::Nostr::Message;
use Net::Nostr::Signer;
# Note: You'll need a WebSocket library like Cro::WebSocket

# Setup
my $pubkey = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
my $privkey = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
my $relay-url = "wss://relay.example.com";

# Connect to relay (pseudo-code)
my $ws = connect-websocket($relay-url);

# Subscribe to events
my $req-msg = Net::Nostr::Message.new-req(
    "my-feed",
    [{ kinds => [1], limit => 50 }]
);
$ws.send($req-msg.to-json());

# Publish a note
my $event = Net::Nostr::Event.new(
    pubkey     => $pubkey,
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Hello from nostraku!",
);
$event.id = $event.calculate-id();

my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $privkey);

my $event-msg = Net::Nostr::Message.new-event($event);
$ws.send($event-msg.to-json());

# Receive events
loop {
    my $message = $ws.receive();
    say "Received: $message";
    # Parse and process event...
}

# Close subscription
my $close-msg = Net::Nostr::Message.new-close("my-feed");
$ws.send($close-msg.to-json());
```

---

## Error Handling

### Type Validation Errors

```raku
use Net::Nostr::Event;

# Invalid pubkey (too short)
try {
    my $event = Net::Nostr::Event.new(
        pubkey     => "invalid",
        created_at => now.Int,
        kind       => 1,
        tags       => [],
        content    => "Test",
    );
    CATCH {
        when X::TypeCheck {
            say "Type error: Pubkey must be 64 hex characters";
        }
    }
}

# Invalid kind (negative)
try {
    my $event = Net::Nostr::Event.new(
        pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
        created_at => now.Int,
        kind       => -1,
        tags       => [],
        content    => "Test",
    );
    CATCH {
        when X::TypeCheck {
            say "Type error: Kind must be non-negative";
        }
    }
}
```

### Signing Errors

```raku
use Net::Nostr::Signer;

my $signer = Net::Nostr::Signer.new;

try {
    my $sig = $signer.sign(
        "a" x 64,  # Valid event ID
        "invalid"  # Invalid private key
    );
    CATCH {
        default {
            say "Signing failed: $_";
        }
    }
}
```

---

## Advanced Usage

### Batch Event Creation

```raku
use Net::Nostr::Event;
use Net::Nostr::Signer;

sub create-batch-events(@contents, $pubkey, $privkey) {
    my $signer = Net::Nostr::Signer.new;
    my @events;
    
    for @contents -> $content {
        my $event = Net::Nostr::Event.new(
            pubkey     => $pubkey,
            created_at => now.Int,
            kind       => 1,
            tags       => [],
            content    => $content,
        );
        
        $event.id = $event.calculate-id();
        $event.sig = $signer.sign($event.id, $privkey);
        
        @events.push($event);
    }
    
    return @events;
}

my @events = create-batch-events(
    ["Hello", "World", "From", "Nostraku"],
    "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144",
);

say "Created {+@events} events";
```

### Event Builder Pattern

```raku
use Net::Nostr::Event;
use Net::Nostr::Signer;

class EventBuilder {
    has $.pubkey is required;
    has $.privkey is required;
    has $.signer = Net::Nostr::Signer.new;
    
    method text-note($content, @tags = []) {
        return self!build-event(1, $content, @tags);
    }
    
    method metadata(%data) {
        use JSON::Fast;
        return self!build-event(0, to-json(%data), []);
    }
    
    method !build-event($kind, $content, @tags) {
        my $event = Net::Nostr::Event.new(
            pubkey     => $!pubkey,
            created_at => now.Int,
            kind       => $kind,
            tags       => @tags,
            content    => $content,
        );
        
        $event.id = $event.calculate-id();
        $event.sig = $!signer.sign($event.id, $!privkey);
        
        return $event;
    }
}

# Usage
my $builder = EventBuilder.new(
    pubkey => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    privkey => "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144",
);

my $note = $builder.text-note("Hello, Nostr!");
my $metadata = $builder.metadata(%(
    name => "Alice",
    about => "Raku developer",
));

say $note.to-json();
say $metadata.to-json();
```

### Event Validation Helper

```raku
use Net::Nostr::Event;

sub validate-event($event) {
    my @errors;
    
    # Check if ID is set
    unless $event.id {
        @errors.push("Event ID is not set");
    }
    
    # Check if signature is set
    unless $event.sig {
        @errors.push("Event signature is not set");
    }
    
    # Verify ID matches content
    unless $event.verify-id() {
        @errors.push("Event ID does not match content");
    }
    
    # Check created_at is not in the future
    if $event.created_at > now.Int + 60 {  # Allow 60s clock skew
        @errors.push("Event timestamp is in the future");
    }
    
    return @errors ?? @errors !! "Event is valid";
}

# Usage
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Test",
);
$event.id = $event.calculate-id();

my $result = validate-event($event);
say $result;
```

---

## Running the Examples

All the code examples above can be saved to `.raku` files and executed:

```bash
# Save example to file
echo 'use Net::Nostr::Event; ...' > example.raku

# Run it
raku example.raku
```

Or run the provided examples in the `examples/` directory:

```bash
raku examples/create-note.raku
raku examples/message-generation-demo.raku
```

---

## Additional Resources

- [API Reference](API.md) - Complete API documentation
- [README](README.md) - Getting started guide
- [Contributing](CONTRIBUTING.md) - Contribution guidelines
- [Nostr NIPs](https://github.com/nostr-protocol/nips) - Protocol specifications
