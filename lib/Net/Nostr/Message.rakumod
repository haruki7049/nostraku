=begin pod

=head1 NAME

Net::Nostr::Message - Nostr protocol message handling

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Message;
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Create an EVENT message
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Hello, Nostr!",
);
$event.id = $event.calculate-id();
my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $private-key);

my $event-msg = Net::Nostr::Message.new-event($event);
say $event-msg.to-json();

# Create a REQ message
my $req-msg = Net::Nostr::Message.new-req(
    "subscription-id-123",
    [
        { kinds => [1], limit => 10 },
        { authors => ["f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320"] },
    ]
);
say $req-msg.to-json();

# Create a CLOSE message
my $close-msg = Net::Nostr::Message.new-close("subscription-id-123");
say $close-msg.to-json();

# Direct stringification
say $event-msg;  # Automatically calls to-json()
=end code

=head1 DESCRIPTION

Net::Nostr::Message provides a high-level interface for creating and serializing
Nostr protocol messages according to NIP-01.

The Nostr protocol uses three main message types for client-to-relay communication:
=item EVENT - Publish an event to the relay
=item REQ - Request events from the relay with optional filters
=item CLOSE - Close a subscription

This class handles the proper formatting and serialization of these messages
for WebSocket transmission.

=head1 TYPES

=head2 MsgType

An exported enum with three values:
=item EVENT - For publishing events
=item REQ - For requesting events  
=item CLOSE - For closing subscriptions

=head1 ATTRIBUTES

=head2 type

Type: MsgType, required

The message type (EVENT, REQ, or CLOSE).

=head2 event

Type: Net::Nostr::Event

The event object for EVENT messages. Required for EVENT type, unused for others.

=head2 subscription-id

Type: Str

The subscription identifier for REQ and CLOSE messages.
Required for REQ and CLOSE types, unused for EVENT.

=head2 filters

Type: Array

Array of filter objects for REQ messages. Each filter is a Hash that can contain:
=item ids - Array of event IDs
=item authors - Array of author public keys
=item kinds - Array of event kinds
=item #e - Array of event IDs referenced in tags
=item #p - Array of pubkeys referenced in tags
=item since - Unix timestamp, events newer than this
=item until - Unix timestamp, events older than this
=item limit - Maximum number of events to return

Required for REQ type, unused for others.

=head1 METHODS

=head2 new-event

=begin code :lang<raku>
method new-event(Net::Nostr::Event $event)
=end code

Factory method to create an EVENT message.
Returns a Net::Nostr::Message configured to publish an event.

Example:
=begin code :lang<raku>
my $msg = Net::Nostr::Message.new-event($event);
=end code

=head2 new-req

=begin code :lang<raku>
method new-req(Str $sub-id, @filters)
=end code

Factory method to create a REQ message.
Returns a Net::Nostr::Message configured to request events with filters.

Parameters:
=item $sub-id - Subscription identifier string
=item @filters - Array of filter hashes

Example:
=begin code :lang<raku>
my $msg = Net::Nostr::Message.new-req(
    "my-sub",
    [{ kinds => [1], limit => 50 }]
);
=end code

=head2 new-close

=begin code :lang<raku>
method new-close(Str $sub-id)
=end code

Factory method to create a CLOSE message.
Returns a Net::Nostr::Message configured to close a subscription.

Parameters:
=item $sub-id - Subscription identifier to close

Example:
=begin code :lang<raku>
my $msg = Net::Nostr::Message.new-close("my-sub");
=end code

=head2 to-json

=begin code :lang<raku>
method to-json() returns Str
=end code

Serializes the message to a JSON string suitable for WebSocket transmission.

The output format depends on message type:
=item EVENT: ["EVENT", <event_object>]
=item REQ: ["REQ", <subscription_id>, <filter1>, <filter2>, ...]
=item CLOSE: ["CLOSE", <subscription_id>]

=head2 Str

=begin code :lang<raku>
method Str() returns Str
=end code

Stringification overload that calls C<to-json()>.
Allows direct use in string context or with C<say>.

Example:
=begin code :lang<raku>
say $msg;  # Automatically calls to-json()
=end code

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Event> - Event representation
=item L<Net::Nostr::Types> - Type definitions

=head1 LICENSE

Artistic-2.0

=end pod

unit class Net::Nostr::Message;

use JSON::Fast;
use Net::Nostr::Event;

enum MsgType is export <EVENT REQ CLOSE>;

has MsgType $.type is required;
has Net::Nostr::Event $.event;
has Str $.subscription-id;
has Array $.filters;

# --- Factory Methods ---

#| Create an EVENT message
method new-event(Net::Nostr::Event $event) {
    return self.new(type => MsgType::EVENT, :$event);
}

#| Create a REQ message
method new-req(Str $sub-id, @filters) {
    return self.new(type => MsgType::REQ, subscription-id => $sub-id, filters => @filters);
}

#| Create a CLOSE message
method new-close(Str $sub-id) {
    return self.new(type => MsgType::CLOSE, subscription-id => $sub-id);
}

# --- Serialization ---

#| Serialize to JSON string for WebSocket transmission
method to-json() returns Str {
    given $!type {
        # NOTE: Add `MsgType::` to avoid conflicts with reserved words

        when MsgType::EVENT {
            # ["EVENT", <event_object>]
            return to-json(["EVENT", $!event.to-hash], :!pretty);
        }
        when MsgType::REQ {
            # ["REQ", <sub_id>, <filter1>, <filter2>, ...]
            return to-json(["REQ", $!subscription-id, |$!filters], :!pretty);
        }
        when MsgType::CLOSE {
            # ["CLOSE", <sub_id>]
            return to-json(["CLOSE", $!subscription-id], :!pretty);
        }
    }
}

#| Stringification overload (allows "say $msg" directly)
method Str() returns Str {
    return self.to-json();
}
