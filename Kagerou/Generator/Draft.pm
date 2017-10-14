use strict;
use warnings;

package Kagerou::Generator::Draft;
use Exporter 'import';
our @EXPORT_OK = qw(draft);

use Mojo::Template;

use Kagerou::Generator::Base qw(base);
use Kagerou::Response;

use Kagerou::User qw(decode_cookie);

my $THREAD_PER_PAGE = 30;

sub draft {
    my($req, $mysql, $redis, $order, $cp) = (@_ ,1);
    my $tmpl = Mojo::Template->new;
    my($r,$page);
    my $order_sql;
    my $title;

    my $res = Kagerou::Response->new;

    my $ucookie = $req->cookies->{user};
    my $uid = decode_cookie($ucookie) if $ucookie;
    return $res->abort(403) if not $uid;

    if($order eq 'published') {
	$order_sql = 'datetime';
      } elsif ($order eq 'replies_count') {
	$order_sql = 'reply_count';
      } elsif ($order eq 'changed') {
	$order_sql = 'last_changed';
      } elsif ($order eq 'brownian_motion') {
	$order_sql = 'RAND()';
      } else {
	return $res->abort(404);
      }

    $mysql->run(sub {
	$r = $_->prepare(
	    'SELECT HEX(Thread.id) AS tid,Thread.title, Thread.datetime AS datetime, '.
	    'User.name AS author,MAX(Post.last_modified) AS last_changed, '.
	    '(SELECT COUNT(*) FROM Post WHERE Post.thread = Thread.id) AS reply_count FROM Thread '.
	    'LEFT JOIN User ON User.id = Thread.author '.
	    'LEFT JOIN Post ON Post.thread = Thread.id AND Post.hidden = FALSE '.
	    "WHERE Thread.hidden = FALSE AND Thread.draft = TRUE AND Thread.Author = UNHEX(?) ".
	    'GROUP BY Thread.id '.
	    "ORDER BY $order_sql DESC ".
	    "LIMIT ?,$THREAD_PER_PAGE"
	    ) or die 'can\'t SELECT';
	my $pr = $_->prepare(
	    "SELECT COUNT(*) FROM Thread WHERE hidden = FALSE AND draft = TRUE AND Thread.Author = UNHEX(?) "
	   );

	$r->execute($uid, ($cp - 1) * $THREAD_PER_PAGE);
	$pr->execute($uid);
	$title = "Drafts";
	($page) = $pr->fetchrow_array;
      });
    $page = int(($page - 1)/$THREAD_PER_PAGE + 1);

    my $baseurl = "/drafts";

    my $inner_page = $tmpl->render_file('Template/list.tmpl',
					$r, $order,
					$cp, $page,
					$baseurl);

    my $outer_page = base($req, $mysql,
			  body => $inner_page,
			  title => $title);

    $res->ok($outer_page);
}

1;
