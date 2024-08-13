use strict;
use warnings;

use Exporter "import";
our @EXPORT_OK= qw<next_double_message serialize_messages serialize_double_messages>;
our @EXPORT=@EXPORT_OK;

#Decoding functions for double precision payloads

sub next_double_message {
	
	#ensure we can read the next length
	my $length=length $_[0];
	if($_[1] >= $length){
		return undef;
	}
	
	#read length and ensure we can take the whole message
	my ($id, $time, $pad_len, $payload_len, $payload)=unpack "vvvvd", $_[0];
	my $msg_len=$pad_len+$payload_len+8;	#total size of the message
	
	#check withing data boundary
	if($msg_len+$_[1] > $length){
		return undef;
	}

	#remove the data from the buffer
	(substr $_[0], 0, $_[1]+$msg_len, "");
	$_[1]=0;

	[$id, $time, $payload, $msg_len];
}


#passing arrays of arrays, id, time, payload
sub serialize_messages {
	my $padding;
	my $length;
	for(splice @_, 2){
		$padding=($length=(4*2+length $_->[2]))%4;
		my $s=pack("v3 v/a* x[$padding]",$_->[0],$_->[1],$padding, $_->[2]);
		$_[0].=$s;
		#say STDERR unpack "H*",$s;
		$_[1]+=$length+$padding;
	}
	
}

sub serialize_double_messages {
	my $padding;
	my $length;
	my $payload;
	for(splice @_, 2){
                $payload=pack "d<", $_->[2];
		$padding=($length=(4*2+length $payload))%4;
		$_[0].=pack("v3 v/a* x[$padding]",$_->[0],$_->[1],$padding, $payload);
		$_[1]+=$length+$padding;
	}
}
	
