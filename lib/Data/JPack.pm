package Data::JPack;
use strict;
use warnings;
use version; our $VERSION=version->declare("0.01");
use feature qw<say switch>;
no warnings "experimental";

use MIME::Base64;
use IO::Compress::RawDeflate qw<rawdeflate>;
use IO::Uncompress::RawInflate qw<rawinflate $RawInflateError>;

use constant B64_BLOCK_SIZE=>(57*71); #Best fit into page size


use Exporter("import");
our @EXPORT_OK=qw<jpack_encode jpack_encode_file jpack_decode_file>;
our @EXPORT=@EXPORT_OK;

# turn any data into locally (serverless) loadable data for html/javascript apps

#represents a chunk of a data to load
#could be a an entire file, or just part of one
#
use enum ('options_=0', qw<compress_ buffer_ src_>);

sub new {
	my $pack=shift//__PACKAGE__;
	#options include
	#	compression
	#	tagName
	#	chunkSeq
	#	relativePath
	#	type
	#
	my $self=[];
	my %options=@_;
	$self->[options_]=\%options;;

	$self->[options_]{jpack_type}//="data";
	$self->[options_]{jpack_compression}//="none";
	$self->[options_]{jpack_seq}//=0;
  $self->[buffer_]="";
	bless $self , $pack;
}

sub encode_header {
	my $self=shift;
	for ($self->[options_]{jpack_compression}){
		if(/deflate/i){
			my %opts;
			my $deflate=IO::Compress::RawDeflate->new(\$self->[buffer_]);

			$self->[compress_]=$deflate;
		}
    else{
		}
	}

  # NOTE: Technically this isn't needed as the RawDefalte does not add the zlib
  # header. However if Deflate is used then this wipes out the header
  #
  $self->[buffer_]="";

	my $header=""; 
	my $options=($self->[options_]);
	if($self->[options_]{embedded}){
		$header.= ""
		. qq|<script defer type="text/javascript" onload="chunkLoaded(this)" |
		. join('', map {qq|$_="|.$options->{$_}.qq|" |} keys %$options)
		. ($self->[options_]{src}? qq|src="|.$self->[options_]{src}.qq|" >\n| : ">\n")
		;
	}

	$header.=""
  #. qq|console.log(document.currentScript);|
		. qq|chunkLoader.decodeData({jpack_path:document.currentScript.src,|
		. join(", ", map {qq|$_:"|.$options->{$_}.qq|"|} keys %$options)
		. qq|}, function(){ return "|;
		;
}

sub encode_footer {
	#force a flush
	my $self=shift;

  # flush internal buffer
  $self->[compress_]->flush() if $self->[compress_];
  # Encode the rest of the the data
  my $rem=encode_base64($self->[buffer_], "" );

	my $footer= $rem .qq|"\n});\n|;


	if($self->[options_]{embedded}){
		$footer.=qq|</script>|;
	}
	$footer;
}

sub encode_data {
	my $self=shift;
  my $data=shift;
  my $out="";
	if($self->[compress_]){
		$self->[compress_]->write($data);
	}
	else {
    # Data might not be correct size for base64 so append
		$self->[buffer_].=$data;
	}
	
  my $multiple=int(length ($self->[buffer_])/B64_BLOCK_SIZE);
  #
  #
  if($multiple){
    # only convert block if data is correcty multiple
   $out=encode_base64(substr($self->[buffer_], 0, $multiple*B64_BLOCK_SIZE,""),"");
  }
  $out;
}


sub encode {
  my $self=shift;
  my $data=shift;

	$self->encode_header
	.$self->encode_data($data)
	.$self->encode_footer
}

#single shot.. non OO
sub jpack_encode {
	my $data=shift;
	my $jpack=Data::JPack->new(@_);

	$jpack->encode($data);
}


sub jpack_encode_file {
	local $/;
	my $path = shift;
	return unless open my $file, "<", $path;
	jpack_encode <$file>, @_;
}

sub decode {
  my $self=shift;
  my $data=shift;
  my $compression; 
  $data=~/decodeData\(\s*\{(.*)\}\s*,\s*function\(\)\{\s*return\s*"(.*)"\s*\}\)/;
  my $js=$1;
  $data=$2;
  my @items=split /\s*,\s*/, $js;
  my %pairs= map {s/^\s+//; s/\s+$//;$_ }
          map {split ":", $_} @items;
  for(keys %pairs){
    if(/compression/){
      $pairs{$_}=~/"(.*)"/;
      $compression=$1;
    }
  }

  my $decoded;
  my $output="";
  for($compression){
    if(/deflate/){
      $decoded=decode_base64($data);
      rawinflate(\$decoded, \$output) or die $RawInflateError;
    }
    else {
      $output=decode_base64($data);
    }
  }
  $output;

}

sub jpack_decode {

}

sub jpack_decode_file {
	local $/;
	my $path=shift;
	return unless open my $file,"<", $path;
	my $data=<$file>;

  my $jpack=Data::JPack->new;
  $jpack->decode($data);
}

1;
