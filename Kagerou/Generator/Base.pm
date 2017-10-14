use strict;
use warnings;

package Kagerou::Generator::Base;
use Exporter 'import';
our @EXPORT_OK = qw(base);

use Kagerou::User qw(decode_cookie);

use Mojo::Template;

my $SECRET_KEY = '414a27730732433896d3a4bdb4442e46';

sub base {
  my($req, $mysql) = @_;
  my %args = (
    title => 'Index',
    body => 'You shouldn\'t be here. WHAT DID YOU DO?!',
    @_
   );
  my($r, $user, $uid);
  my $cookie = $req->cookies->{user};
  if ($cookie) {
    $uid = decode_cookie($cookie);
  }
  $mysql->run(
    sub {
      $r = $_->prepare('SELECT name,HEX(id) FROM Category '.
			 'ORDER BY id');
      $r->execute;
      if ($uid) {
	my $ur = $_->prepare(
	  'SELECT name, email, '.
	    'LOWER(MD5(TRIM(LOWER(email)))) AS avatar '.
	    'FROM User WHERE id = UNHEX(?)');
	$ur->execute($uid);
	$user = $ur->fetchrow_hashref;
      }
    });    
  my $tmpl = Mojo::Template->new;
  $tmpl->render_file('Template/base.tmpl',
		     $args{title},
		     $args{body},
		     $r, $user);
}

1;
