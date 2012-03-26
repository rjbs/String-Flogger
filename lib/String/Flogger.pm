use strict;
use warnings;
package String::Flogger;
# ABSTRACT: string munging for loggers

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

  and we can defer evaluation of stuff if we want

  while avoiding sprintfiness, if needed

=method flog

This method is described in the synopsis.

=method format_string

  $flogger->format_string($fmt, \@input);

This method is used to take the formatted arguments for a format string (when
C<flog> is passed an arrayref) and turn it into a string.  By default, it just
uses C<L<perlfunc/sprintf>>.

=cut

sub _encrefs {
  my ($self, $messages) = @_;
  return map { blessed($_) ? sprintf('obj(%s)', "$_")
             : ref $_      ? $self->_stringify_ref($_)
             : defined $_  ? $_
             :              '{{null}}' }
         map { _CODELIKE($_) ? scalar $_->() : $_ }
         @$messages;
}

my $JSON;
sub _stringify_ref {
  my ($self, $ref) = @_;

  if (ref $ref eq 'SCALAR' or ref $ref eq 'REF') {
    my ($str) = $self->_encrefs([ $$ref ]);
    return "ref($str)";
  }

  require JSON;
  $JSON ||= JSON->new
                ->ascii(1)
                ->canonical(1)
                ->allow_nonref(1)
                ->space_after(1)
                ->convert_blessed(1);

  return '{{' . $JSON->encode($ref) . '}}'
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
    return $class->format_string($fmt, $class->_encrefs(\@data));
  }

  return $class->format_string('%s', $class->_encrefs([$input]));
}

sub format_string {
  my ($self, $fmt, @input) = @_;
  sprintf $fmt, @input;
}

1;
