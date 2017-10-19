use strict;
use warnings;

package Kagerou::Generator::Post;
use Exporter 'import';
our @EXPORT_OK = qw(view);

use Mojo::Template;
use DateTime;

use Kagerou::Generator::Base qw(base);
use Kagerou::User qw(decode_cookie);
use Kagerou::Response;

my $POST_PER_PAGE = 30;

sub view {
  my($req, $mysql, $redis, $tid, $cp, $admin) = @_;
  my($rp,$rt);
  my $page;
  my $error;
  my $tmpl = Mojo::Template->new;
  my $uid = decode_cookie($req->cookies->{user});

  my $taid;

  $cp = $cp ? $cp : 1;
    
  $mysql->run(
    sub {
      $rt = $_->prepare(
	'SELECT title FROM Thread WHERE id = UNHEX(?)'
       );
      $rt->execute($tid);
      my $pr = $_->prepare(
	'SELECT COUNT(*) FROM Post WHERE thread = UNHEX(?)'
       );
      $pr->execute($tid);
      my($pc) = $pr->fetchrow_array;
      $page = int(($pc - 1) / $POST_PER_PAGE + 1);
    });
    
  $mysql->run(
    sub {
      $rp = $_->prepare(
	'SELECT HEX(Post.id) as pid,User.name AS author, '.
	  'HEX(Post.author) AS aid, '.
	  'LOWER(MD5(TRIM(LOWER(User.email)))) as avatar, '.
	  'PostContent.content, PostContent.datetime, PostContent.renderer FROM Post '.
	  'INNER JOIN User ON User.id = Post.author '.
	  'INNER JOIN Thread ON Thread.id = Post.thread '.
	  'INNER JOIN PostContent ON PostContent.id = Post.content '.
	  'WHERE Post.thread = UNHEX(?) AND Post.hidden = FALSE '.
	  "ORDER BY Post.datetime LIMIT ?,$POST_PER_PAGE");
      $rp->execute($tid,($cp - 1) * $POST_PER_PAGE);
      
      my $tap = $_->prepare(
	'SELECT HEX(Thread.author) FROM Thread WHERE id = UNHEX(?)'
       );
      $tap->execute($tid);
      $taid = $tap->fetchrow_array;
    });
    
  my $title = $rt->fetchrow_hashref->{title};
  my $inner_page = $tmpl->render_file('Template/post.tmpl', 
				      $rp, $cp, $page, $POST_PER_PAGE,
				      "/thread/view/$tid", $uid, $tid, $admin);
    
  my $outer_page = base($req, $mysql, 
			body => $inner_page, 
			title => $title);
  my $res = Kagerou::Response->new;
  $res->ok($outer_page);
}

1;
