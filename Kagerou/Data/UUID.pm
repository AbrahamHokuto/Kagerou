use strict;
use warnings;

package Kagerou::Data::UUID;
use Exporter 'import';
our @EXPORT_OK = qw(uuid);

use UUID;

sub uuid {
  my $uuid, $string;
  UUID::generate($uuid);
  UUID::unparse($uuid, $string);  
  $string =~ s/-//g;
  return uc $string;
}

1;
