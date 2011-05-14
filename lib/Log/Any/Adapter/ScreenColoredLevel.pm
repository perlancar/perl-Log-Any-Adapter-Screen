package Log::Any::Adapter::ScreenColoredLevel;
# ABSTRACT: Send logs to screen with colorized messages according to level

use 5.010;
use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);
use Term::ANSIColor;

my @logging_methods = Log::Any->logging_methods;
my %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}

sub _default_level {
    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    'warning';
}

sub init {
    my ($self) = @_;
    $self->{stderr}    //= 1;
    $self->{use_color} //= (-t STDOUT);
    $self->{colors}    //= {
        trace     => 'yellow',
        debug     => '',
        info      => 'green',
        notice    => 'green',
        warning   => 'blue',
        error     => 'magenta',
        critical  => 'red',
        alert     => 'red',
        emergency => 'red',
    };
    $self->{min_level} //= _default_level();
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $format, @params) = @_;

            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};
            if ($self->{use_color}) {
                $format = Term::ANSIColor::colored(
                    $format, $self->{colors}{$method} // "");
            }
            my $nl = $format =~ /\R\z/ ? "" : "\n";

            if ($self->{stderr}) {
                print STDERR $format, $nl;
            } else {
                print $format, $nl;
            }
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my ($self) = @_;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
__END__

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('ScreenColoredLevel',
     # min_level => 'debug', # default is 'warning'
     # colors    => { trace => 'bold yellow on_gray', ... }, # customize colors
     # use_color => 1, # force color even when not interactive
     # stderr    => 0, # print to STDOUT instead of STDERR
 );


=head1 DESCRIPTION

This Log::Any adapter prints log messages to screen (STDERR/STDOUT) colored
according to level. It is just like
L<Log::Log4perl::Appender::ScreenColoredLevel>, even down to the default colors,
except that you don't have to use Log::Log4perl.

Parameters:

=over 4

=item * min_level => STRING

Set logging level. Default is warning. If LOG_LEVEL environment variable is set,
it will be used instead. If TRACE environment variable is set to true, level
will be set to 'trace'. If DEBUG environment variable is set to true, level will
be set to 'debug'. If VERBOSE environment variable is set to true, level will be
set to 'info'.If QUIET environment variable is set to true, level will be set to
'error'.

=item * use_color => BOOL

Whether to use color or not. Default is true only when running interactively (-t
STDOUT returns true).

=item * colors => HASH

Customize colors. Hash keys are the logging methods, hash values are colors
supported by L<Term::ANSIColor>.

The default colors are:

 method/level                 color
 ------------                 -----
 trace                        yellow
 debug                        (none, terminal default)
 info, notice                 green
 warning                      blue
 error                        magenta
 critical, alert, emergency   red

=item * stderr => BOOL

Whether to print to STDERR, default is true. If set to 0, will print to STDOUT
instead.

=back

=for Pod::Coverage init


=head1 SEE ALSO

L<Log::Any>

L<Log::Log4perl::Appender::ScreenColoredLevel>

L<Term::ANSIColor>