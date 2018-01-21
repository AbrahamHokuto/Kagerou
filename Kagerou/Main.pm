use strict;
use warnings;

package Kagerou::Main;

use Kagerou::Generator::Thread qw(index category);
use Kagerou::Generator::Post qw(view);
use Kagerou::Generator::Login qw(login logout);
use Kagerou::Generator::NewThread qw(new_thread_view);
use Kagerou::Generator::Edit qw(edit_view);
use Kagerou::Generator::Avatar qw(avatar_view);
use Kagerou::Generator::Draft qw(draft);
use Kagerou::Generator::Register qw(register);

use Kagerou::Action::Reply qw(reply);
use Kagerou::Action::NewThread qw(new_thread);
use Kagerou::Action::Edit qw(edit);
use Kagerou::Action::Avatar qw(avatar);

use Kagerou::Response;

use Kagerou::Config;

use DBIx::Connector;
use Mojo::Template;
use Redis::Fast;
use Encode;

Kagerou::Config->init('../config.json');

my $DB   = Kagerou::Config->get("db/name");
my $HOST = Kagerou::Config->get("db/host");
my $USER = Kagerou::Config->get("db/user");
my $PWD  = Kagerou::Config->get("db/password");

my $mysql = DBIx::Connector->new("DBI:mysql:database=$DB:host=$HOST",
				 $USER,$PWD);
$mysql->mode('fixup');

my $redis = Redis::Fast->new;

my @ROUTER = (
	      ['/index/by_([a-z_]+)' => \&index],
	      ['/index/by_([a-z_]+)/([0-9]+)' => \&index],

	      ['/drafts/by_([a-z_]+)' => \&draft],
	      ['/drafts/by_([a-z_]+)/([0-9]+)' => \&draft],

	      ['/category/([A-Z0-9]+)' => \&category],
	      ['/category/([A-Z0-9]+)/by_([a-z_]+)' => \&category],
	      ['/category/([A-Z0-9]+)/by_([a-z_]+)/([0-9]+)' => \&category],

	      ['/thread/view/([A-Z0-9]+)' => \&view],
              ['/thread/view/([A-Z0-9]+)/(\d+)' => \&view],
              ['/thread/view/([A-Z0-9]+)/(\d+)/(admin)' => \&view],

	      ['/(thread|post)/edit/([A-F0-9]+)' => \&edit_view],

	      ['/login' => \&login],
	      ['/logout' => \&logout],
	      ['/register' => \&register],

	      ['/new' => \&new_thread_view],

	      ['/settings/avatar' => \&avatar_view],

	      ['/action/reply' => \&reply],
	      ['/action/new_thread' => \&new_thread],
	      ['/action/edit/(thread|post)/([A-F0-9]+)' => \&edit],
	      ['/action/change_avatar' => \&avatar]
	     );

sub router {
  my $url = shift;
  for my $i (@ROUTER) {
    my($pattern, $handler) = @{$i};
    if ($url =~ m/^$pattern$/) {
      my @matches = ($url =~ m/^$pattern$/);
      return ($handler, \@matches);
    }
  }
  return undef;
}

sub main {
  my $req = shift;
  Kagerou::Config->init;
  my $res;

  my ($handler, $match) = router($req->path_info);
  if (defined($handler)) {
    $res = $handler->($req, $mysql, $redis, @{$match});
  } else {
    $res = Kagerou::Response->new->abort(404);
  }

  return $res;
}
