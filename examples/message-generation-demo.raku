use v6.d;

use Net::Nostr::Message;
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Dummy key set
my $privkey = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
my $pubkey  = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";

my $event = Net::Nostr::Event.new(
    pubkey     => $pubkey,
    created_at => now.Int,
    kind       => 1,
    content    => "This is a decoupled message demo via Raku!",
    tags       => [],
);

# Calculates ID
$event.id = $event.calculate-id();

# Signing
my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $privkey);

# Creates a message
my $msg = Net::Nostr::Message.new-event($event);

say "To create Json for Message, you can create Net::Nostr::Message instance, then you can use to-json method and Str method.";
say "";
say "Message's Json: " ~ $msg.to-json;
say "This Json can be created by Str method implemented at Net::Nostr::Message: " ~ $msg;
say "";

say "=== REQ Message Demo ===";
say "";

my $req-msg = Net::Nostr::Message.new-req(
    "sub-id-1234",
    [
        {
            kinds => [1],
            limit => 10,
        },

        {
            authors => [$pubkey],
        },
    ]
);

say "You can create a REQUEST message by new-req method, from Net::Nostr::Message class.";
say "This is a generated REQUEST message by Net::Nostr::Message : " ~ $req-msg;
say "";

say "=== CLOSE Message Demo ===";
say "";

my $close-msg = Net::Nostr::Message.new-close("sub-id-1234");

say "You also can create a CLOSE message by new-close method, from Net::Nostr::Message class.";
say "This is a generated CLOSE message by Net::Nostr::Message : " ~ $close-msg;
