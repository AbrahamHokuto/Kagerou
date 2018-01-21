use strict;
use warnings;

package Kagerou::User;

use Exporter 'import';
our @EXPORT = qw(encode_cookie decode_cookie);

use Digest::SHA qw(sha256_hex);

use Kagerou::Config;

# my $SECRET_KEY = '414a27730732433896d3a4bdb4442e46';
# my $SECRET_KEY_ADMIN = '2342271d5f1e3243915d6d89e1d42e28';

sub encode_cookie {
  my $uid = shift;
  my $secret_key = Kagerou::Config->get('cookie_salt');
  my $sign = sha256_hex($uid ^ $secret_key);
  my $cookie = "$uid|$sign";
  return $cookie;
}

sub decode_cookie {
  my $cookie = shift;
  my $secret_key = Kagerou::Config->get('cookie_salt');
  my($uid,$sign) = split /\|/,$cookie;
  if($sign and $sign eq sha256_hex($uid^$secret_key)) {
    return $uid;
  }
}

# sub encode_admin {
#   my $uid = shift;
#   my $secret_key = Kagerou::Config->get('secret_key_admin');
#   my $sign = sha256_hex($uid ^ $secret_key);
#   my $cookie = "$uid|$sign";
#   return $cookie;
# }

# sub decode_admin {
#   my $cookie = shift;
#   my $secret_key = Kagerou::Config->get('secret_key_admin');
#   my($uid,$sign) = split /\|/,$cookie;
#   if($sign and $sign eq sha256_hex($uid^$secret_key)) {
#     return $uid;
#   }
}

1;
