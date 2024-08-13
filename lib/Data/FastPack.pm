package Data::FastPack;
use strict;
use warnings;

our $VERSION="v0.0.1";

use feature ":all";
no warnings "experimental";
use Export::These qw<decode_message encode_message FP_MSG_TIME FP_MSG_ID FP_MSG_PAYLOAD FP_MSG_TOTAL_LEN encode_meta_payload decode_meta_payload>;



use constant::more <FP_MSG_{TIME=0,ID,PAYLOAD,TOTAL_LEN}>;

# routine indicating the required size of a buffer to store the requested
# payload length
#
sub size_message {
  my $payload_size=shift;
		my$padding=($payload_size%8);
    $padding= 8-$padding  if $padding;

    #return the total length of the head, payload and padding
    16+$payload_size+$padding;
}

#passing arrays of arrays, [time, info, payload] Computes padding, appends
#the serialized data to the supplied buffer, and sets the length.  If id
#has MORE bit set, at least one more messags to follow (at some point).
#$buf, [$time, $id, $data]
#
my $pbuf= pack "x8";


sub encode_message {
  \my $buf=\$_[0]; shift;
  my $inputs=shift;
  my $limit=shift;

  $limit//=@$inputs;
  my $processed=0;
	my $padding;
  
  my $flags=0;

	for(@$inputs){
		$padding=((length $_->[FP_MSG_PAYLOAD])%8);
    $padding= 8-$padding  if $padding;

		my $s=pack("d V V/a*", @$_);
		$buf.=$s.substr $pbuf, 0, $padding;
    next if ++$processed == $limit;
	}
  $processed;	
}

# Decode a message from a buffer. Buffer is aliased
sub decode_message {
  \my $buf=\$_[0]; shift;
  my $output=shift;
  my $limit=shift//4096;

  my $byte_count=0;
  for(1..$limit){
    # Minimum message length 8 bytes long (header)
    last if length($buf)<16;

    # Decode  header. Leave length for in buffer
    my @message= unpack "d V V", substr($buf, 0, 16);



    # Calculate pad. Payload in message here is actuall just length atm
    my $pad= $message[FP_MSG_PAYLOAD]%8;
    $pad=8-$pad if $pad;

    # Calculate total length
    my $total=$message[FP_MSG_PAYLOAD]+16+$pad;

    last if(length($buf)<$total);




    $byte_count+=$total;


    ($message[FP_MSG_PAYLOAD],undef)=unpack "V/a* ", substr($buf,12);
    push @message, $total;

    # remove from buffer
    substr($buf, 0, $total,"");
    push @$output, \@message;
  }
  $byte_count;
}

# Meta / structured data encoding and decoding
# ============================================
#
# Structured or meta data messages are always of id 0. They
#

use Cpanel::JSON::XS;
use Data::MessagePack;

my $mp=Data::MessagePack->new();
$mp->prefer_integer(1);
$mp->utf8(1);

# Arguments: $payload, force_mp Forcing message pack decode is only needed if
# the encoded data is not of map or array type. Otherise automatic decoding is
# best
sub decode_meta_payload {
	my ($payload,$force_mp)=@_;
	my $decodedMessage;
  
	for(unpack("C", $payload)) {
		if (!$force_mp and ($_== 0x5B || $_== 0x7B)) {
			#JSON encoded string
			$decodedMessage=decode_json($payload);
		}
    else { 
			#msgpack encoded
			$decodedMessage=$mp->unpack($payload);
		}
	}
	$decodedMessage;
}

# Arguments: payload, force_mp
sub encode_meta_payload {
  $_[1]?$mp->encode($_[0]):encode_json($_[0]);
}

1;
