package TAP::Harness::Remote::EC2;

our $VERSION = '0.01';

use warnings;
use strict;

use base 'TAP::Harness::Remote';
use constant config_path => "$ENV{HOME}/.remote_test_ec2";
use Net::Amazon::EC2;

=head1 NAME

TAP::Harness::Remote::EC2 - Run tests on EC2 servers

=head1 SYNOPSIS

    prove --harness TAP::Harness::Remote::EC2 t/*.t

=head1 DESCRIPTION

Based on L<TAP::Harness::Remote>, this module uses your running Amazon
EC2 instances (L<http://amazon.com/ec2>) to run tests against, instead
of a preconfigured list of hosts.

=head1 USAGE

Configuration is much the same as L<TAP::Harness::Remote>, except the
configuration file lives in C</.remote_test_ec2> -- see
L</"CONFIGURATION AND ENVIRONMENT">.  Note the
L<TAP::Harness::Remote::EC2> does not, at current, start EC2 hosts
itself, nor differentiate in any way between running EC2 hosts; it
attempts to connect and run tests on all currently running EC2 hosts.

=head1 METHODS

=head2 load_remote_config

Loads and canonicalizes the configuration.  Writes and uses the
default configuration (L</default_config>) if the file does not exist.

=cut

sub load_remote_config {
    my $self = shift;

    $self->SUPER::load_remote_config;
    warn
        "Useless 'host' configuration parameter set for TAP::Harness::Remote::EC2\n"
        if grep {defined} @{$self->remote_config("host")};
    delete $self->{remote_config}{host};

    die "Configuration failed to include required 'access_key' parameter\n"
        unless $self->remote_config("access_key");

    die
        "Configuration failed to include required 'secret_access_key' parameter\n"
        unless $self->remote_config("secret_access_key");

    my $ec2 = Net::Amazon::EC2->new(
        AWSAccessKeyId  => $self->remote_config("access_key"),
        SecretAccessKey => $self->remote_config("secret_access_key"),
    );

    my $running_instances = $ec2->describe_instances;

    my @hosts = map { $_->dns_name }
        grep { $_->instance_state->name eq "running" }
        map { @{ $_->instances_set } } @{$running_instances};

    die "No EC2 hosts active\n" unless @hosts;
    $self->{remote_config}{host} = \@hosts;
    return $self;
}

=head1 CONFIGURATION AND ENVIRONMENT

The configuration is stored in F<~/.remote_test_ec2>, and is mostly
identical to the configuration of L<TAP::Harness::Remote> (see
L<TAP::Harness::Remote/"CONFIGURATION AND ENVIRONMENT">), with the
following differences:

=over

=item *

The C<hosts> parameter is ignored, and produces a warning if present.

=item *

The C<access_key> amd C<secret_access_key> parameters are required, to
be able to query the Amazon EC2 interface and determine the running
EC2 hosts.  You can find your access keys at
L<https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key>

=back

=head1 DEPENDENCIES

L<Net::Amazon::EC2>

=head1 BUGS AND LIMITATIONS

The default perl installed Amazon's provided EC2 images is
B<extremely> slow (about 4x slower than a clean, optimized build).  We
thus strongly suggest you compile your own.

In the future, L<TAP::Harness::Remote::EC2> may provide configuration
options so that it can start and stop testing instances on demand.

=head1 AUTHOR

Alex Vandiver  C<< <alexmv@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2008, Best Practical Solutions, LLC.  All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;