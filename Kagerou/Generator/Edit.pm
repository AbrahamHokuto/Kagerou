use strict;
use warnings;

package Kagerou::Generator::Edit;
use Exporter 'import';
our @EXPORT_OK = qw(edit_view);

use Kagerou::User qw(decode_cookie);
use Kagerou::Response;

use Kagerou::Generator::Base qw(base);

sub edit_view {
  my($req, $mysql, $redis, $type, $oid) = @_;
  my $res = Kagerou::Response->new;

  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if ($ucookie);
  return $res->abort(403) if not $uid;

  my $referer = $req->referer;

  my($pc, $pt, $pp);

  if ($type eq 'thread') {
    $mysql->run(
      sub {
	$pc = $_->prepare(
	  'SELECT name, HEX(id) FROM Category ORDER BY id'
	 );
	$pc->execute;

	$pt = $_->prepare(
	  'SELECT title, HEX(category), draft, COUNT(*) FROM Thread '.
	    'WHERE id = UNHEX(?) AND author = UNHEX(?)'
	   );
	$pt->execute($oid, $uid);

	$pp = $_->prepare(
	  'SELECT PostContent.content, PostContent.renderer FROM Post '.
	    'INNER JOIN PostContent ON PostContent.id = Post.content '.
	    'WHERE thread = UNHEX(?) and Post.author = UNHEX(?) '.
	    'ORDER BY Post.datetime LIMIT 1'
	   );
	$pp->execute($oid, $uid);
      }
     );
  } else {
    $mysql->run(
      sub {
	$pp = $_->prepare(
	  'SELECT PostContent.content, PostContent.renderer FROM Post '.
	    'INNER JOIN PostContent ON PostContent.post = Post.id '.
	    'WHERE Post.id = UNHEX(?) and Post.author = UNHEX(?) '
	   );
	$pp->execute($oid, $uid);
      });
  }
  
  my($content, $renderer) = $pp->fetchrow_array;
  
  my($title, $category, $draft) = $pt->fetchrow_array if ($type eq 'thread');

  my $tmpl = Mojo::Template->new;
  my $inner_page = $tmpl->render_file(
    'Template/edit.tmpl', $pc, $title, $category,
    $content, $draft, $renderer, $referer, $type, $oid
   );
  my $outer_page = base($req, $mysql,
			body => $inner_page,
			title => "New Thread");
  $res->ok($outer_page);
}

1;
