use strict;
use warnings;

package Kagerou::Response;

use Plack::Response;

sub new {
    my $ret = { res => Plack::Response->new };
    bless $ret;
    return $ret;
}

sub cookies {
    my $self = shift;
    return $self->{res}->cookies;
}

sub ok {
    my($self, $page) = @_;
    my $res = $self->{res};
    
    my $options = {
	ContentType => 'text/html',
	@_
    };

    $page = ($page ? $page : '');
    $res->status(200);
    $res->body($page);
    $res->content_type($options->{ContentType});
    $res->content_length(length($page));

    $res->finalize;    
}

sub redirect {
    my($self, $url, $permanent) = @_;
    my $res = $self->{res};
    
    my $status = ($permanent ? 301 : 302);
    
    $res->status($status);
    $res->body('Redirecting...');
    $res->content_type('text/plain');
    $res->content_length(length('Redirecting...'));    
    $res->redirect($url);

    $res->finalize;
}    

sub abort {
    my($self, $code, $reason) = @_;
    my $res = $self->{res};

    my $body = 'Aborted.';
    $body .= "Reason: $reason" if $reason;
    
    $res->status($code);
    $res->body($body);
    $res->content_type('text/plain');
    $res->content_length(length($body));

    $res->finalize;    
}

1;
