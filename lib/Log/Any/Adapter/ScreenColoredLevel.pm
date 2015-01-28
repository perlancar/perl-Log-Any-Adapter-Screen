package Log::Any::Adapter::ScreenColoredLevel;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);
use Term::ANSIColor;

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

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
        warning   => 'bold blue',
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
            my ($self, $msg) = @_;

            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

            my $nl = $msg =~ /\R\z/ ? "" : "\n";

            if ($self->{formatter}) {
                $msg = $self->{formatter}->($self, $msg);
            }

            if ($self->{use_color} && $self->{colors}{$method}) {
                $msg = Term::ANSIColor::colored($msg, $self->{colors}{$method});
            }

            if ($self->{stderr}) {
                print STDERR $msg, $nl;
            } else {
                print $msg, $nl;
            }
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my $self = shift;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
# ABSTRACT: Send logs to screen with colorized messages according to level

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('ScreenColoredLevel',
     # min_level => 'debug', # default is 'warning'
     # colors    => { trace => 'bold yellow on_gray', ... }, # customize colors
     # use_color => 1, # force color even when not interactive
     # stderr    => 0, # print to STDOUT instead of STDERR
     # formatter => sub { "LOG: $_[1]" }, # default none
 );


=head1 DESCRIPTION

This Log::Any adapter prints log messages to screen (STDERR/STDOUT) colored
according to level. It is just like
L<Log::Log4perl::Appender::ScreenColoredLevel>, even down to the default colors
(with a tiny difference), except that you don't have to use Log::Log4perl. Of
course, unlike Log4perl, it only logs to screen and has minimal features.

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
 warning                      bold blue
 error                        magenta
 critical, alert, emergency   red

=item * stderr => BOOL

Whether to print to STDERR, default is true. If set to 0, will print to STDOUT
instead.

=item * formatter => CODEREF

Allow formatting message. Default is none.

Message will be passed before being colorized. Coderef will be passed:

 ($self, $message)

and is expected to return the formatted message.

=back

=for Pod::Coverage init


=head1 SEE ALSO

L<Log::Any>

L<Log::Log4perl::Appender::ScreenColoredLevel>

L<Term::ANSIColor>
