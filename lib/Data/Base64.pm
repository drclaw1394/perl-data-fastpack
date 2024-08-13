use strict;
use warnings;
use feature ":all";
no warnings "experimental";
package Data::Base64;
use version; our $VERSION=version->declare("v0.0.1");
use AnyEvent;
use Promise::XS qw<deferred>;
use IO::AIO;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IPC::Open2;

use Data::Dumper;
use Errno qw(:POSIX);
use Data::FIFO;
use File::Basename();

use constant {
	PID=>0,			#PID of child
	W_CHIN=>1,		#watcher of in
	W_CHOUT=>2,		#watcher of out
	W_CHERR=>3,		#watcher of err
	W_CHLD=>4,		#watcher of sigchild
	CHIN=>5,
	CHOUT=>6,
	DEF=>7,
	PATH=>8

};

#Encodes data from a fifo to a file
#File can be a path,filehandle or file descriptor
#Asynchronously reads from fifo
#Pass output fd so writing is direct
sub createWithFileOutput($outputFH) {
	my $o=[];
	return $o;
}
sub new($pack=__PACKAGE__){
	my $o=[];
	bless $o,$pack;

}

sub basename($o){
	File::Basename::basename $o->[PATH];
}

sub open($o,$path){
	say "Creating new file: $path";
	$o->[DEF]=deferred;
	$o->[PATH]=$path;
	my $def=deferred;
	aio_open($path, IO::AIO::O_RDWR | IO::AIO::O_CREAT | IO::AIO::O_TRUNC, 0666, sub {
			say "OPEN CB $path:", $!;
			say $path, Dumper $_[0];

			$o->[CHOUT]=$_[0];	#This needs to seek at child end
			$def->resolve($_[0]);
		});
	return $def->promise()
	->then(sub {
			openProcess($o);
			Promise::XS::resolved;
	});
}
	#link to the output of fifo
sub drainData::FIFO($o,$fifo){

}

sub writeToFromData::FIFO($o,$fifo){
	my $buffer=Data::FIFO::pop $fifo;
	writeToFromBuffer($o,\$buffer);
}


sub writeToFromBuffer($o,$buffer){
#setup a watcher and wait for output to become writable
#Called by notEmpty callback
	#Try to get next item from fifo

	my $def=deferred;

	unless(defined $$buffer){
		$def->resolve([0,0]);
		return $def->promise();
	}
	my $len=length $$buffer;
	#say "SETTING UP WATCHER ", Dumper $o;
	#We have data.. now try and write, when ready
	$o->[W_CHIN]=AE::io $o->[CHIN], 1, sub {
		#say "in io watcher";
		my $res=syswrite $o->[CHIN], $$buffer;
		#say "RES", $res;
		unless (defined $res){
			if($! == EAGAIN) {
			#Would have blocked
			#leave the buffer for next time
			#watcher will get called when ready and repeat this
			}
		}
		else {
			
			if($res==length $$buffer){
				#say "Complete write";
				#This was a full write. cancel watcher and resolve promise
				#
				$$buffer=undef;#buffer is done
				$o->[W_CHIN]=undef; #stop watcher
				$def->resolve([1,$len]);
			}
			else {
				#partial write. Adjust buffer and let watcher do its thing
				$$buffer=substr $$buffer,$res;
			}
		}
			
	};
	return $def->promise();
}

sub close($o){
	return closeProcess($o)
	->then(sub {
		writeFooter($o);
	})
	->then( sub {
		my $def=deferred;
		aio_close($o->[CHOUT],sub {
				say "CLOSE CB";
				$o->[CHOUT]=undef;
				$def->resolve(0);
			});
		return $def->promise();
	})
}

#Call this on done to close input to sub process.
#child watcher in create resolves promise when child is done
sub closeProcess($o){
	CORE::close $o->[CHIN];
	say "Closed CHIN";
	return $o->[DEF]->promise();
}
sub openProcess($o){

	#my $cmd="./deflate|./base64-encode";
	my $cmd="./deflatebase64";
	my $pid=open2(">&".fileno $o->[CHOUT], my $chIn,$cmd);
	$o->[CHIN]=$chIn;
        my $flags=fcntl($o->[CHIN], F_GETFL,0);
        fcntl $o->[CHIN],F_SETFL, $flags & O_NONBLOCK;
        $o->[W_CHLD]= AE::child $pid, sub {
                #Seek the
                say "Child closed ", Dumper $o->[CHOUT];
                $o->[DEF]->resolve(1);
        };

	$o->[PID]=$pid;
}

#Build the script element for injection into the html
sub  externalScriptElement($o,$options){

	my $out = qq|<script defer type="text/javascript" onload="chunkLoaded(this)" |;
	for( keys %$options ){
		$out.= qq|$_="$options->{$_}" |;
	}
	$out.=qq|></script>|;
	$out;
}
#

sub buildExternalScriptFromData::FIFO {
	#write
}

#when done start the main process
sub writeHeader($o,$options){
	my $header=qq|chunkLoader.decodeData({|;
	for( keys %$options ){
		$header.= qq|$_:"$options->{$_}", |;
	}
	$header.=qq|},function(){return "|;
	writeOut($o,$header);
}

#write the end of JSONP
sub writeFooter($o){
	#Append remaining JSONP data	
	#my $def=Promise::XS::deferred;
	say "Writing footer";
	my $block=qq|" });|;

        ####################################################
        # aio_seek($o->[CHOUT],0, IO::AIO::SEEK_END, sub { #
        #                 say @_;                          #
        #                 say "Seek callback";             #
        #                                                  #
        #         writeOut($o,$block)                      #
        #         ->then(sub {                             #
        #                 say "about to resolve";          #
        #                 $def->resolve();                 #
        #         });                                      #
        # });                                              #
        ####################################################

	writeOut($o,$block);
	#return $def->promise();
}

#Write to the buffer  returns promise.
sub writeOut ($o, $buffer){
	say "in write out: $buffer";
	my $def=deferred;
	my $wCount=0;
	my $_write;
	$_write=sub {
		say "_write";	
		aio_write $o->[CHOUT],undef,-$wCount+length($buffer),$buffer,$wCount,sub {
			say "AIO_WRITE CB";
			$wCount+=$_[0];
			if($wCount <length $buffer){
				&$_write;
			}
			else {
				say "Write out complete";
				$def->resolve($wCount);
				
			}
		};

	};
	&$_write;
	return $def->promise();
}
