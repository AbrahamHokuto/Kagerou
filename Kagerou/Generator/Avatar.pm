use strict;
use warnings;

package Kagerou::Generator::Avatar;

use Exporter 'import';
our @EXPORT_OK = qw(avatar_view);

use Mojo::Template;

use Kagerou::Generator::Base qw(base);
use Kagerou::User qw(decode_cookie);
use Kagerou::Response;

sub avatar_view {
  my($req, $mysql, $redis) = @_;
  my $res = Kagerou::Response->new;
  
  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if ($ucookie);
  return $res->redirect("/") if not $uid;

  my $tmpl = Mojo::Template->new;
  my $page = $tmpl->render_file('Template/avatar.tmpl');
  $res->ok(base($req, $mysql, title => 'Avatar', body => $page ));
}

1;
