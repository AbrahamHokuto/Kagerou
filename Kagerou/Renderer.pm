use strict;
use warnings;

package Kagerou::Renderer;

use HTML::Entities ();
use Text::Markdown::Hoedown;
use Encode;

sub render {
    my $src = shift;
    my %options = @_;
    return render_pod($src, %options) if $options{renderer} eq 'simpod';
    return render_plain($src, %options) if $options{renderer} eq 'plain';    
    return render_markdown($src, %options) if $options{renderer} eq 'markdown';
}

sub render_plain {
    my $src = decode('utf-8', shift);
    HTML::Entities::encode($src);
    my $ret;
    $ret .= "<p>$_</p>" foreach (split /\n/, $src);
    return $ret;
}

sub render_pod {
    # 1 - NORMAL
    # 2 - CODE
    my $status = 1;
    sub inline_tags {
	my($tags,$content) = @_;
	my $ret = $content;
	$ret =~ s/\\&gt;/&gt;/g;
	$ret = "<a href='$content'>$content</a>" if index($tags,'L') != -1;
	$ret = "<b>$content</b>" if index($tags,'B') != -1;
	$ret = "<i>$content</i>" if index($tags,'I') != -1;
	$ret = "<code>$content</code>" if index($tags,'C') != -1;
	$ret = "<img src='$content'>" if index($tags,'i') != -1;
	return $ret;
    }
    sub head {
	my($lv,$content) = @_;
	encode_entities($content);
	$content = "<h$lv>$content</h$lv>";
    }
    my $cont = shift;
    my @lines = split /\n/,$cont;
    my $lang;
    my $ret;
    foreach my $l (@lines) {
	if ($status == 1) {
	    if ($l =~ m/^=head([0-7]) (.*)$/) {
		$l = head($1,$2);
		$ret .= $l;
	    } elsif ($l =~ m/^=begin code lang=([A-Za-z0-9_-]+)/) {
		$lang = $1;
		$status = 2;
		$ret .= "<pre><code lang='$lang'>";
	    } else {
		encode_entities($l);
		$l =~ s/([BIL]{1,3})&lt;(((?:(?!&gt;).)|\\&gt;)*)&gt;/inline_tags($1,$2)/ge;
		$l =~ s/([BIL]{1,3})&lt;&lt; ((?:(?! &gt;&gt;).)*) &gt;&gt;/inline_tags($1,$2)/ge;
		$ret .= "<p>$l</p>";
	    }
	} elsif ($status == 2) {
	    if ($l =~ '^=end\w*$') {
		$status = 1;
		$ret .= "</code></pre>";
	    } else {
		encode_entites($l);
		$ret .= "$l\n";
	    }
	}
    }
    return $ret;
}

sub render_markdown {
    sub escape_formula {
	my $formula = shift;
	$formula =~ s/([_*\\{}()])/\\$1/g;
	return $formula;
    }    
    sub remove_needless_slash {
	my $formula = shift;
	$formula =~ s/\\([_*\\{}()])/$1/g;
	return $formula;
    }
    my $content = shift;
    $content =~ s/\n/\n\n/g;
    $content =~ s/(```(.*?)```)/join "\n",split "\n\n",$1/sge;
    $content =~ s/(\\\((.+?)\\\))/escape_formula($1)/ge;
    $content =~ s/(\$(.+?)\$)/escape_formula($1)/ge;
    $content =~ s/```math(.*?)```/$1/sg;
    my $rendered = markdown(
	$content,
	extensions => HOEDOWN_EXT_FENCED_CODE|HOEDOWN_EXT_STRIKETHROUGH,
	html_options => HOEDOWN_HTML_ESCAPE);
    $rendered =~ s/(\\\((.+?)\\\))/remove_needless_slash($1)/ge;
    $rendered =~ s/(\$(.+?)\$)/remove_needless_slash($1)/ge;
    return $rendered;
}


1;
