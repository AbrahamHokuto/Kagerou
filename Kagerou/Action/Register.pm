use strict;
use warnings;

package Kagerou::Action::NewThread;
use Exporter 'import';
our @EXPORT_OK = qw(new_thread);

use DateTime;

use Kagerou::Response;
use Kagerou::User qw(decode_cookie);

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
      my $ptid = $_->prepare('SELECT REPLACE(UUID(), "-", "")');
      $ptid->execute;
      $tid = uc(($ptid->fetchrow_array)[0]);
      
      my $pt = $_->prepare('
             INSERT INTO Thread VALUES (
               UNHEX(?), UNHEX(?), UNHEX(?), ?, ?, FALSE, ?
             )');
      
      my $pp = $_->prepare(
	'INSERT INTO Post VALUES ('.
	  'UNHEX(REPLACE(UUID(),\'-\',\'\')),'.
	  'UNHEX(?), UNHEX(?), ?, ?, FALSE, ?, ?)'
	 );
      eval {
	$pt->execute($tid, $uid, $cid, $now, $title, $draft);
	$pp->execute($uid, $tid, $now, $content, $renderer, $now);
      };
    });

  $redis->setnx("new_thread_cooldown_$uid", 0);
  $redis->expire("new_thread_cooldown_$uid", 2);

  $res->redirect("/thread/view/$tid");
}
