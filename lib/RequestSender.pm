package RequestSender;

use strict;
use warnings;

use Carp qw(croak);
use Mojo::UserAgent;
use Data::Dumper::OneLine;

use base qw(Exporter);

our @EXPORT_OK = qw(
	send_request
);

our %EXPORT_TAGS = (
	all => [@EXPORT_OK],
);

sub send_request {
	my $inst = shift;
	my %args = (
		method => 'get',
		url => undef,
		port => undef,
		args => {},
		@_,
	);

	$args{url} = "http://localhost/$args{url}" if defined $args{url};

	$inst->app->log->debug(sprintf "Sending request [method: %s] [url: %s] [port: %d] [args: %s]",
		uc($args{method}), $args{url}, $args{port}, Dumper $args{args});

	croak 'url not specified' unless $args{url};

	my $url = Mojo::URL->new($args{url});
	$url->port($args{port}) if defined $args{port};

	my $ua = Mojo::UserAgent->new();

	my @ua_args = ($url => json => $args{args});
	my %switch = (
		get	=> sub { $url->query(%{$args{args}}); return $ua->get($url); },
		post	=> sub { return $ua->post(@ua_args); },
		put	=> sub { return $ua->put(@ua_args); },
		delete	=> sub { return $ua->delete(@ua_args); },
	);

	my $s = $switch{$args{method}};
	croak "unknown metod specified" unless defined $s;

	my $resp = $s->()->res->json();
	unless (defined $resp) {
		$inst->app->log->warn("Response is undefined");
	} else {
		$inst->app->log->debug("Response: " . Dumper($resp));
	}

	return $resp;
}