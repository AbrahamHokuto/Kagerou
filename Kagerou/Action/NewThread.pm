use strict;
use warnings;

package Kagerou::Action::NewThread;
use Exporter 'import';
our @EXPORT_OK = qw(new_thread);

use DateTime;

use Kagerou::Response;
use Kagerou::User qw(decode_cookie);
use Kagerou::Data::UUID qw(uuid);

sub new_thread {
  my($req, $mysql, $redis) = @_;
  my $res = Kagerou::Response->new;

  my $now = DateTime->now;
  
  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if $ucookie;

  return $res->abort(403) if not $uid;

  return $res->ok(
    'Are you flooding?',
    ContentType => "text/plain"
   ) if $redis->get("new_thread_cooldown_$uid");

  my $params = $req->parameters;

  my $title = $params->{title};
  my $cid = $params->{category};
  my $renderer = $params->{renderer};
  my $content = $params->{content};
  my $draft = $params->{draft};

  my $tid;
  
  $mysql->run(
    ping => sub {
      $tid = uuid;
      my $pcid = uuid;
      my $pid = uuid;

      my $pt = $_->prepare(
	'INSERT INTO Thread VALUES ('.
	  'UNHEX(?), UNHEX(?), UNHEX(?), ?, ?, FALSE, ?'.
	  ')');
      
      my $pp = $_->prepare(
	'INSERT INTO Post VALUES ('.
	  'UNHEX(?), UNHEX(?), UNHEX(?), ?, FALSE, ?, UNHEX(?))'
	 );

      my $pc = $_->prepare(
	'INSERT INTO PostContent VALUES('.
	  'UNHEX(?), UNHEX(?), UNHEX(?), ?, ?, ?)'
	 );
      eval {
	$pt->execute($tid, $uid, $cid, $now, $title, $draft);
	$pp->execute($pid, $uid, $tid, $now, $now, $pcid);
	$pc->execute($pcid, $pid, $uid, $content, $renderer, $now);
      };
    });

  $redis->setnx("new_thread_cooldown_$uid", 0);
  $redis->expire("new_thread_cooldown_$uid", 2);

  $res->redirect("/thread/view/$tid");
}
