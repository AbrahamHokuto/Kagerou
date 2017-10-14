use strict;
use warnings;

package Kagerou::Action::Edit;
use Exporter 'import';
our @EXPORT_OK = qw(edit);

use DateTime;
use Kagerou::Response;
use Kagerou::Data::UUID qw(uuid);
use Kagerou::User qw(decode_cookie);

sub edit {
  my($req, $mysql, $redis, $type, $oid) = @_;
  my $res = Kagerou::Response->new;

  my $now = DateTime->now;

  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if $ucookie;
  return $res->abort(403) if not $uid;

  return $res->ok(
    'Are you flooding?',
    ContentType => "text/plain"
   ) if $redis->get("edit_cooldown_$uid");

  my $params = $req->parameters;

  my $renderer = $params->{renderer};
  my $content = $params->{content};
  my $referer = $params->{referer};

  my $tid;
  my $pcid = uuid;
  
  if ($type eq 'thread') {
    my $title = $params->{title};
    my $cid = $params->{category};
    my $draft = $params->{draft};

    $mysql->run(
      sub {
	my $pt = $_->prepare(
	  'UPDATE Thread SET title = ?, category = UNHEX(?), draft = ? '.
	    'WHERE id = UNHEX(?) and author = UNHEX(?)'
	   );	
	$pt->execute($title, $cid, $draft, $oid, $uid);

	my $pp = $_->prepare(
	  'UPDATE Post SET content = UNHEX(?), '.
	    'last_modified = ? '.
	    'WHERE thread = UNHEX(?) and author = UNHEX(?) '.
	    'ORDER BY datetime LIMIT 1'
	   );

	my $pc = $_->prepare(
	  'INSERT INTO PostContent VALUES ('.
	    'UNHEX(?), '.
	    '(SELECT id from Post WHERE thread = UNHEX(?) and author = UNHEX(?) '.
	    'ORDER BY datetime LIMIT 1), UNHEX(?), ?, ?, ?)');
	eval{ $pp->execute($pcid, $now, $oid, $uid); };
	eval{ $pc->execute($pcid, $oid, $uid, $uid, $content, $renderer, $now); };
	$tid = $oid;
      });
  } else {
    $mysql->run(
      sub {
	my $pp = $_->prepare(
	  'UPDATE Post SET content = UNHEX(?), '.
	    'last_modified = ? WHERE id = UNHEX(?) '.
	    'and author = UNHEX(?)'
	   );
	my $pc = $_->prepare(
	  'INSERT INTO PostContent VALUES ('.
	    'UNHEX(?), UNHEX(?), UNHEX(?), ?, ?, ?)');
	eval{ $pp->execute($pcid, $now, $oid, $uid); };
	eval{ $pc->execute($pcid, $oid, $uid, $content, $renderer, $now); };
	my $tidp = $_->prepare(
	  'SELECT UNHEX(thread) FROM Post WHERE id = UNHEX(?)'
	 );
	eval{ $tidp->execute($oid); };
	($tid) = $tidp->fetchrow_array;
      });
  }
  
  $referer = "/thread/view/$tid" if !($referer =~ m/\/thread\/view\/([A-F0-9]+)/);
  $referer .= "#post-$oid" if ($type eq 'post');
  $res->redirect($referer);
}

1;
