use strict;
use warnings;

package Kagerou::Config;

use Redis::Fast;

my $redis;

sub init {
  $redis = Redis::Fast->new;
}

sub get {
  shift;
  my $key = shift;
  $redis->get("config:$key");
}

sub set {
  shift;
  my ($key, $val) = @_;
  $redis->set("config:$key" => "$val");
}

1;
