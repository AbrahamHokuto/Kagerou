use strict;
use warnings;

package Kagerou::Config;

use Config::JSON;

my $config;

sub init {
    shift;
    my $config_path = shift;
    print "$config_path\n";
    $config = Config::JSON->new($config_path);
}

sub get {
  shift;
  $config->get(shift);
}

sub set {
  shift;
  my ($key, $val) = @_;
  $config->set($key, $val);
}

1;
