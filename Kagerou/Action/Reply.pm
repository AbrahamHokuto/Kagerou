use strict;
use warnings;

package Kagerou::Action::Reply;
use Exporter 'import';
our @EXPORT_OK = qw(reply);

use Kagerou::Response;
use Kagerou::Data::UUID qw(uuid);
use Kagerou::User qw(decode_cookie);

sub reply {
    my($req, $mysql, $redis) = @_;
    my $res = Kagerou::Response->new;

    my $uid = decode_cookie($req->cookies->{user});
    my($param, $renderer, $content, $tid) = ($req->parameters);

    return $res->abort(403) if not $uid;

    $redis->setnx("reply_count_$uid", 0);

    if ($redis->get("reply_count_$uid") >= 60) {
	return $res->ok(
	    'Are you spamming?',
	    ContentType => "text/plain"
	    );
    }

    $redis->incr("reply_count_$uid");
    $redis->expire("reply_count_$uid", 60);

    $renderer = $param->{renderer};
    $content = $param->{content};
    $tid = $param->{tid};
    my $pid = uuid;
    my $pcid = uuid;
    my $now = DateTime->now;
    $mysql->run(
	ping => sub {
	    my $pp = $_->prepare(
		'INSERT INTO Post VALUES ('.
		'UNHEX(?), UNHEX(?), UNHEX(?), ?, FALSE, ?, UNHEX(?))'
	       );
	    my $pc = $_->prepare(
	      'INSERT INTO PostContent VALUES ('.
		'UNHEX(?), UNHEX(?), UNHEX(?), ?, ?, ?)');
	    eval { $pp->execute($pid, $uid, $tid, $now, $now, $pcid); };
	    eval { $pc->execute($pcid, $pid, $uid, $content, $renderer, $now); }
	});

    $redis->incr("reply_count_$uid");

    $res->redirect($req->referer);
}

1;
