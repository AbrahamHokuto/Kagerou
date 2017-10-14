# -*- mode:cperl -*-

use Plack::Request;
use Kagerou::Main qw(main);

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    return Kagerou::Main::main($req);
};
