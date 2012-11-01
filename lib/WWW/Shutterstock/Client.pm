package WWW::Shutterstock::Client;

use strict;
use warnings;
use Moo;
use Carp qw(croak);
use JSON qw(decode_json);

extends 'REST::Client';

sub response {
	my $self = shift;
	if(@_){
		$self->{_res} = $_[0];
	}
	return $self->{_res};
}

sub GET {
	my($self, $url, $query, $headers) = @_;
	if(ref($query) eq 'HASH'){
		$url .= $self->buildQuery(%$query);
	}
	$self->SUPER::GET($url, $headers);
	return $self->response;
}

sub DELETE {
	my($self, $url, $query, $headers) = @_;
	if(ref($query) eq 'HASH'){
		$url .= $self->buildQuery(%$query);
	}
	$self->SUPER::DELETE($url, $headers);
	return $self->response;
}

sub PUT {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::PUT($url, $content, $headers);
	return $self->response;
}

sub POST {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::POST($url, $content, $headers);
	return $self->response;
}

sub process_response {
	my $self = shift;
	my %handlers = (
		204 => sub { 1 }, # empty response, but success
		401 => sub { croak "invalid api_username or api_key"; },
		@_
	);

	my $code = $self->responseCode;
	my $content_type = $self->responseHeader('Content-Type');

	my $response = $self->{_res}; # blech, why isn't this public?
	my $request = $response->request;

	if(my $h = $handlers{$code}){
		$h->($response);
	} elsif($code <= 299){ # a success
		return $content_type =~ m{^application/json} && $self->responseContent ? decode_json($self->responseContent) : $response->decoded_content;
	} elsif($code <= 399){ # a redirect of some sort
		return $self->responseHeader('Location');
	} elsif($code <= 499){ # client-side error
		croak sprintf("Error executing %s against %s: %s\n%s", $request->method, $request->uri, $response->status_line, $response->as_string);
	} elsif($code >= 500){ # server-side error
		croak sprintf("Error executing %s against %s: %s\n%s", $request->method, $request->uri, $response->status_line, $response->as_string);
	}
}

1;