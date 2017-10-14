use strict;
use warnings;

package Kagerou::Generator::Register;
use Exporter 'import';
our @EXPORT_OK = qw(register);

use Kagerou::User qw(encode_cookie);
use Kagerou::Generator::Base qw(base);
use Kagerou::Response;

use Mojo::Template;
use Encode qw(decode);

sub register {
  my($req, $mysql, $redis) = @_;
  my $tmpl = Mojo::Template->new;

  my $res = Kagerou::Response->new;

  if ($req->method eq "GET") {
    my $referer = $req->referer;
    my $p = $tmpl->render_file('Template/register.tmpl',$referer);
    $res->ok(base($req,$mysql,body => $p,title => "Register"));
  } elsif ($req->method eq "POST") {
    my $uid;
    my($user, $pwd, $email, $referer);
    my $params = $req->parameters;
    $user = $params->{username};
    $pwd = $params->{password};
    $email = $params->{email};
    $referer = $params->{referer};
    $referer = '/' if (not $referer) or ($referer =~ '.*/login');
    $mysql->run(
      sub {
	my $sth = $_->prepare(
	  'SELECT HEX(id) AS uid FROM User '.
	    'WHERE name = ?'
	   );
	$sth->execute($user);
	$uid = eval { $sth->fetchrow_hashref->{uid} };
      });

    if ($uid) {
      my $p = $tmpl->render_file('Template/register.tmpl', $referer,
				 "User \"$user\" already exists");
      $res->ok(base($req, $mysql, body => $p, title => "Register"));
    } else {
      $mysql->run(
	ping => sub {
	  my $puid = $_->prepare('SELECT REPLACE(UUID(), "-", "")');
	  $puid->execute;
	  $uid = uc(($puid->fetchrow_array)[0]);

	  my $pu = $_->prepare(
	    'INSERT INTO User VALUES ('.
	      'UNHEX(?), ?, ?, UNHEX(SHA2(?, 256))'.
	      ')');
	  eval {
	    $pu->execute($uid, $user, $email, $pwd);
	  }
	});
      $res->redirect($referer);
    }
  }
}

1;
