use strict;
use warnings;

package Kagerou::Generator::Thread;
use Exporter 'import';
our @EXPORT_OK = qw(index category);

use Mojo::Template;

use Kagerou::Generator::Base qw(base);
use Kagerou::Response;

my $THREAD_PER_PAGE = 30;

sub list {
    my($req, $mysql, $redis, $order, $cp, $cid) = @_;
    my $tmpl = Mojo::Template->new;
    my($r,$page);
    my $order_sql;
    my $category_sql = '';
    my $title;

    my $res = Kagerou::Response->new;
    
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
    
    if(defined $cid) {
	$category_sql = "AND Thread.category = UNHEX(?)";
    }
    
    $mysql->run(sub {
	$r = $_->prepare(
	    'SELECT HEX(Thread.id) AS tid,Thread.title, Thread.datetime AS datetime, '.
	    'User.name AS author,MAX(Post.last_modified) AS last_changed, '.
	    '(SELECT COUNT(*) FROM Post WHERE Post.thread = Thread.id) AS reply_count FROM Thread '.
	    'INNER JOIN User ON User.id = Thread.author '.
	    'INNER JOIN Post ON Post.thread = Thread.id AND Post.hidden = FALSE '.
	    "WHERE Thread.hidden = FALSE AND Thread.draft = FALSE $category_sql".
	    'GROUP BY Thread.id '.
	    "ORDER BY $order_sql DESC ".
	    "LIMIT ?,$THREAD_PER_PAGE"
	    ) or die 'can\'t SELECT';
	my $pr = $_->prepare(
	    "SELECT COUNT(*) FROM Thread WHERE hidden = FALSE AND draft = FALSE $category_sql"
	    );
	my $cr = $_->prepare(
	    "SELECT name FROM Category WHERE id = UNHEX(?)"
	    );	
	if (defined $cid) {
	    $r->execute($cid,($cp - 1) * $THREAD_PER_PAGE);
	    $pr->execute($cid);
	    $cr->execute($cid);
	    my($category) = $cr->fetchrow_array;
	    $title = "Category:$category";
	} else {
	    $r->execute(($cp - 1) * $THREAD_PER_PAGE);
	    $pr->execute;
	    $title = "Index";
	}
	($page) = $pr->fetchrow_array;
		});
    $page = int(($page - 1)/$THREAD_PER_PAGE + 1);

    my $baseurl;
    if(defined $cid) {
	$baseurl = "/category/$cid";
    } else {
	$baseurl = "/index";
    }

    my $inner_page = $tmpl->render_file('Template/list.tmpl',
					$r, $order,
					$cp, $page,
					$baseurl);
    
    my $outer_page = base($req, $mysql, 
			  body => $inner_page,
			  title => $title);
    
    $res->ok($outer_page);
}

sub index {
    my($req, $mysql, $redis, $order_by, $page) = @_;
    $page = $page ? $page : 1;
    $order_by = $order_by ? $order_by : 'changed';
    list($req, $mysql, $redis, $order_by, $page);
}

sub category {
    my($req, $mysql, $redis, $category, $order_by_or_page, $page) = @_;
    $order_by_or_page = $order_by_or_page ? $order_by_or_page : 'changed';
    if (not $page) {
	if ($order_by_or_page =~ /^\d+$/) {
	    $page = $order_by_or_page;
	    $order_by_or_page = 'changed';
	} else {
	    $page = 1;
	}
    }

    list($req, $mysql, $redis, $order_by_or_page, $page, $category);
}

1;
