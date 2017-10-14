use strict;
use warnings;

package Kagerou::Data::UUID;
use Exporter 'import';
our @EXPORT_OK = qw(uuid);

use UUID;

sub uuid {
  my $uuid = UUID::uuid;
  $uuid =~ s/-//g;
  return uc $uuid;
}

1;
