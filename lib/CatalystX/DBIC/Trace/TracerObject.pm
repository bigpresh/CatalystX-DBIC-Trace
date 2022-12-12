package CatalystX::DBIC::Trace::TracerObject;

use strict;
use Moose;
use namespace::autoclean;

use Time::HiRes;

use base 'DBIx::Class::Storage::Statistics';

=head1 NAME

CatalystX::DBIC::Trace::TracerObject

=head1 DESCRIPTION

An object used by L<CatalystX::DBIC::Trace> to pass to DBIC's C<debugobj()>
to receive trace information on queries being executed.

It can log them as they happen, and assemble a full list with timing
information to be handled at the end.

=cut

has context => (is => 'rw');
has start_times => ( is => 'rw', isa => 'HashRef', default => sub {{}});
has queries => ( is => 'rw', isa => 'ArrayRef', default => sub {[]});

sub query_start {
  my ($self, $string, @bind) = @_;
  $self->context->log->debug("Query starts: $string with bind params: ", @bind);

  my $key = join ":", $string, @bind;
  $self->start_times->{$key} = Time::HiRes::time();
}


sub query_end {
  my ($self, $string, @bind) = @_;
  my $key = join ":", $string, @bind;
  my $started = delete $self->start_times->{$key};
  my $ended = Time::HiRes::time();
  my $took = sprintf '%.3f', $ended - $started;
  $self->context->log->debug("Query ends after $took secs: $string with bind params: ", @bind);
  push @{ $self->queries }, {
      started => $started,
      ended   => $ended,
      took    => $took,
      query   => $string,
      params  => \@bind,
  };
}


__PACKAGE__->meta->make_immutable;
1;

