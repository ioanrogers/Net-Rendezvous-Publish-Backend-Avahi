package Net::Rendezvous::Publish::Backend::Avahi;

# ABSTRACT: Publish zeroconf data via Avahi

# vi: ts=4 sw=4

use strict;
use warnings;

use Net::DBus;

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	my $bus = Net::DBus->system;
	$self->{service} = $bus->get_service('org.freedesktop.Avahi');
	$self->{server} = $self->{service}->get_object(
		'/', 'org.freedesktop.Avahi.Server');

	return $self;
}

sub publish {
	my $self = shift;
	my %args = @_;

	# AddService argument signature is aay.  Split first into key/value
	# pairs at character \x01 ... 
	my $txt = $args{txt} || [];
	unless (ref $txt) {
		$txt = [map {
			[(split //, $_)]
		} (split /\x01/, $txt)];
	}
	# ... then map characters to bytes and add DBus type.
	if (@{$txt}) {
		foreach my $t (@{$txt}) {
			map {
				$_ = Net::DBus::dbus_byte(ord($_))
			} @{$t};
		}
	}

	my $group = $self->{service}->get_object(
		$self->{server}->EntryGroupNew, 'org.freedesktop.Avahi.EntryGroup');
	$group->AddService(Net::DBus::dbus_int32(-1), Net::DBus::dbus_int32(-1),
		Net::DBus::dbus_uint32(0), $args{name}, $args{type},
		$args{domain}, $args{host}, Net::DBus::dbus_uint16($args{port}),
		$txt);

	$group->Commit;

	return $group;
}

sub publish_stop {
	my $self = shift;
	my ($group) = @_;

	$group->Free;
}

sub step {
}

1;

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Jack Bates.  All rights reserved.

Copyright (c) 2012 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

=over

=item L<Net::Rendezvous::Publish> - The module this module supports.

=item L<Avahi|http://avahi.org/>

=back

