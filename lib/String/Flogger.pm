use strict;
use warnings;
package String::Flogger;
# ABSTRACT - string munging for loggers

use Params::Util qw(_ARRAYLIKE _CODELIKE);
use Scalar::Util qw(blessed);
use Sub::Exporter::Util ();
use Sub::Exporter -setup => [ flog => Sub::Exporter::Util::curry_method ];

=head1 SYNOPSIS

  use String::Flogger qw(flog);

  my @inputs = (
    'simple!',

    [ 'slightly %s complex', 'more' ],

    [ 'and inline some data: %s', { look => 'data!' } ],

    [ 'and we can defer evaluation of %s if we want', sub { 'stuff' } ],

    sub { 'while avoiding sprintfiness, if needed' },
  );

  say flog($_) for @inputs;

The above will output:

  simple!

  slightly more complex

  and inline some data: {{{ "look": "data!" }}}

  and we can defer evaluation of %s if we want

  while avoiding sprintfiness, if needed

=cut

sub _encrefs {
  my ($self, $messages) = @_;
  return map { ref $_ ? ('{{' . $self->_stringify_ref($_) . '}}') : $_ }
         map { blessed($_) ? sprintf('obj(%s)', "$_") : $_ }
         map { _CODELIKE($_) ? scalar $_->() : $_ }
         @$messages;
}

my $JSON;
sub _stringify_ref {
  my ($self, $ref) = @_;

  require JSON;
  $JSON ||= JSON->new
                ->ascii(1)
                ->canonical(1)
                ->allow_nonref(1)
                ->space_after(1)
                ->convert_blessed(1);

  return $JSON->encode($ref)
}

sub flog {
  my ($class, $input) = @_;

  my $output;

  if (_CODELIKE($input)) {
    $input = $input->();
  }

  return $input unless ref $input;

  if (_ARRAYLIKE($input)) {
    my ($fmt, @data) = @$input;
    return sprintf $fmt, $class->_encrefs(\@data);
  }

  return $class->_encrefs([ $input ]);
}

1;
