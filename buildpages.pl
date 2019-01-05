#! /usr/bin/perl

use JSON;
use File::Copy;

open(PT, 'templates/pageframework.html') or
    die "Can't open page framework template";

@pagetemplate = <PT>;
close(PT);

open(MS, 'menustructure.json') or
    die "Can't open menustructure";

@mslines = <MS>;
close(MS);

$menustructure = decode_json("@mslines");

# construct header html to insert into all page templates

open(HT, 'templates/header.html') or
    die "Can't open page header template";

@headertemplate = <HT>;
close(HT);

@headerhtml = ();

foreach $line (@headertemplate) {
    if ($line =~ /##__tophref__##/) {
        foreach $g (@{$menustructure}) {
            $tophref = $g->{link}->[0]->{href}; # first page of side menu
            $toptext = $g->{topmenutext};
            $linkline = $line;
            $linkline =~ s/##__tophref__##/$tophref/g;
            $linkline =~ s/##__toptext__##/$toptext/g;
            push(@headerhtml, $linkline);
        }
    } else {
        push(@headerhtml, $line);
    }
}

print "@headerhtml"; #debug#

# generate pages for each top level group

foreach $g (@{$menustructure}) {
    @leftmenulinks = @{$g->{link}};

    foreach $lm (@leftmenulinks) {
        $pagehref = $lm->{href};
        $linktext = $lm->{text};

        if ($pagehref !~ /#/) {
	    # generate page
	    open(PC, "content/$pagehref") or
		die "Can't open $pagehref";

	    @pagecontent = <PC>;
	    close(PC);

	    @pagehtml = ();

	    foreach $pline (@pagetemplate) {
		if ($pline =~ /##__header__##/) {
		    # insert header with top level menu
		    push(@pagehtml, @headerhtml);
		} elsif ($pline =~ /##__lefthref__##/) {
		    # insert side menu entries 
		    foreach $link (@leftmenulinks) {
		    # highlight menu item for current page
			if ($pagehref eq $link->{href}) {
			    $class = 'thispage'
			} else {
			    $class = ''
			}

			$pagehref2 = $link->{href};
			$linktext2 = $link->{text};
                        $linkline = $pline;
			$linkline =~ s/##__lefthref__##/$pagehref2/g;
			$linkline =~ s/##__lefttext__##/$linktext2/g;
			$linkline =~ s/##__leftclass__##/$class/g;
			push (@pagehtml, $linkline);
		    }
		} elsif ($pline =~ /##__content__##/) {
		    # insert content 
		    push(@pagehtml, @pagecontent);
		} else {
		    push(@pagehtml, $pline);
		}
	    }

            # check if any changes have been made
            $releasefile = "release/$pagehref";
            if (-f $releasefile) {
                open(RF, $releasefile) or
                    die "Can't open existing release $pagehref";
            
                @existinghtml = <RF>;
                close(RF);
            } else {
                @existinghtml = ();
            }

            if ("@existinghtml" ne "@pagehtml") {
                open (RF, ">$releasefile") or
                    die "Can't update release $pagehref";

     	        print RF @pagehtml;
                close(RF);
                print "$pagehref updated\n";
            } else {
                print "$pagehref unchanged\n";
            }
        }
    }
}

# refresh released images if changed or added
publishfiles("images");
publishfiles("css");
publishfiles("docs");
exit;


sub publishfiles {
    my $srcdir = shift;

    (opendir PUBSRC, $srcdir) or
        die "Missing publish source dir: $srcdir";

    my @pubfiles = readdir(PUBSRC);
    closedir(PUBSRC);

    foreach my $srcname (@pubfiles) {
        my $src = "$srcdir/$srcname";
        my $tgt = "release/$srcname";
        next unless (-f $src); # avoid directories including . and ..

        if (-f $tgt) {
            my $srcsize = (stat $src)[7];
            my $tgtsize = (stat $tgt)[7];
            if ($srcsize == $tgtsize) { # skip if same date
                print "$srcname unchanged\n";
                next;
            }
        }

        print "$srcname updated\n";

        copy($src, $tgt) or
            die "Failed to publish file $src: $!";
    }
}
