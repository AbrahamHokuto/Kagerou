use strict;
use warnings;

package Kagerou::Action::Avatar;

use Exporter 'import';
our @EXPORT_OK = qw(avatar);

use Mojo::Template;

use Kagerou::Generator::Base qw(base);
use Kagerou::User qw(decode_cookie);
use Kagerou::Response;
use Kagerou::Config;

use Image::Resize;

sub avatar {
  my($req, $mysql, $redis) = @_;
  my $res = Kagerou::Response->new;
  my $avatar_path = Kagerou::Config->get('avatar_path');
  my $ucookie = $req->cookies->{user};
  my $uid = decode_cookie($ucookie) if ($ucookie);
  return $res->abort(403) if not $uid;

  my $upload = $req->uploads->{avatar};

  my $avatar;
  $mysql->run(
    sub {
      my $h = $_->prepare(
	"SELECT TRIM(LOWER(MD5(LOWER(email)))) FROM User WHERE id = UNHEX(?)"
       );
      $h->execute($uid);
      $avatar = $h->fetch->[0];
    }
   );

  my $resizer = Image::Resize->new($upload->path);
  
  my $image = $resizer->resize(200, 200, 0);
  open FH, ">$avatar_path/200/$avatar.png";
  print FH $image->png;
  close FH;

  $image = $resizer->resize(60, 60, 0);
  open FH, ">$avatar_path/60/$avatar.png";
  print FH $image->png;
  close FH;

  $res->redirect('/settings/avatar');
}

1;
