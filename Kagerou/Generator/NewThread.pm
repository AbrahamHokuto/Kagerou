use strict;
use warnings;

package Kagerou::Generator::NewThread;
use Exporter 'import';
our @EXPORT_OK = qw(new_thread_view);

use Kagerou::User qw(decode_cookie);
use Kagerou::Response;

use Kagerou::Generator::Base qw(base);

sub new_thread_view {
  my($req, $mysql, $redis) = @_;
  my $res = Kagerou::Response->new;
  
  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if ($ucookie);
  return $res->redirect("/") if not $uid;
  
  my $q_res;
  $mysql->run(
    sub {
      $q_res = $_->prepare(
	'SELECT name, HEX(id) FROM Category ORDER BY id'
       );
      $q_res->execute;
    }
   );

  my $tmpl = Mojo::Template->new;
  my $inner_page = $tmpl->render_file(
    'Template/new.tmpl', $q_res
   );
  my $outer_page = base($req, $mysql,
			body => $inner_page,
			title => "New Thread");
  $res->ok($outer_page);
}

1;
