use strict;
use warnings;

package Kagerou::Generator::Login;
use Exporter 'import';
our @EXPORT_OK = qw(login logout);

use Kagerou::User qw(encode_cookie);
use Kagerou::Generator::Base qw(base);
use Kagerou::Response;

use Mojo::Template;
use Encode qw(decode);

sub login {
    my($req, $mysql, $redis) = @_;
    my $tmpl = Mojo::Template->new;

    my $res = Kagerou::Response->new;
    
    if($req->method eq "GET") {
	my $referer = $req->referer;
	my $p = $tmpl->render_file('Template/login.tmpl',$referer);	
	$res->ok(base($req,$mysql,body => $p,title => "Login"));
    } elsif ($req->method eq "POST") {
	my $uid;
	my($user, $pwd, $referer);
	my $params = $req->parameters;
	$user = $params->{username};
	$pwd = $params->{password};
	$referer = $params->{referer};
	$referer = '/' if (not $referer) or ($referer =~ '.*/login');
	$mysql->run(
	    sub {
		my $sth = $_->prepare(
		    'SELECT HEX(id) AS uid FROM User '.
		    'WHERE name = ? AND password = UNHEX(SHA2(?,256))'
		    );
		$sth->execute($user,$pwd);
		$uid = eval { $sth->fetchrow_hashref->{uid} };
	    });
	
	if($uid) {
	    my $cookie = encode_cookie($uid);

	    $res->cookies->{user} = {
		value => $cookie,
		expires => 32503680000
	    };
	    $res->redirect($referer);
	    
	} else {
	    my $p = $tmpl->render_file(
		'Template/login.tmpl', $referer,
		'Invalid user or password. Please try again.');
	    $res->ok(base($req, $mysql, body => $p, title => "Login"));
	}
    }
}

sub logout {
    my $req = shift;
    my $res = Kagerou::Response->new;
    
    my $referer = $req->referer;
    $referer = $referer ? $referer : "/";
    
    $res->cookies->{user} = {
	value => '',
	expires => 1
    };
    
    $res->redirect($referer);    
}

1;
