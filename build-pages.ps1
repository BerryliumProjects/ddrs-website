$pagetemplate = gc 'templates\pageframework.html'
$menustructure = [XML] (gc "menustructure.xml")

# construct header html to insert into all page templates
$headertemplate = gc "templates\header.html"
$headerhtml = @()

foreach ($line in $headertemplate) {
    if ($line -match '##__tophref__##') {
        foreach ($g in $menustructure.groups.group) {
            $linkline = $line -replace '##__tophref__##', @($g.link)[0].href
            $linkline = $linkline -replace '##__toptext__##', $g.topmenutext
            $headerhtml += $linkline
        }
    } else {
        $headerhtml += $line
    }
}

$headerhtml #debug#

# generate pages for each top level group

foreach ($g in $menustructure.groups.group) {
    $leftmenulinks = @($g.link) # make list to ensure can be indexed if only one entry

    foreach ($lm in $leftmenulinks) {
        $pagehref = $lm.href
        $linktext = $lm.text
        if ($pagehref -notmatch '#') {
	        # generate page
	        $pagecontent = gc "content\$pagehref"
	        $pagehtml = @()

	        foreach ($pline in $pagetemplate) {
		        if ($pline -match '##__header__##') {
		            # insert header with top level menu
		            foreach ($hline in $headerhtml) {
			        $pagehtml += $hline
		            }
		        } elseif ($pline -match '##__lefthref__##') {
		            # insert side menu entries 
		            foreach ($link in $leftmenulinks) {
			        # highlight menu item for current page
			        if ($pagehref -eq $link.href) {
			            $class = 'thispage'
			        } else {
			            $class = ''
			        }

			        $linkline = $pline -replace '##__lefthref__##', $link.href
			        $linkline = $linkline -replace '##__lefttext__##', $link.text
			        $linkline = $linkline -replace '##__leftclass__##', $class
			        $pagehtml += $linkline
		            }
		        } elseif ($pline -match '##__content__##') {
		            # insert content 
		            foreach ($cline in $pagecontent) {
			        $pagehtml += $cline
		            }
	               } else {
		            $pagehtml += $pline
		        }
	        }

            # check if any changes have been made
            if (test-path "release\$pagehref" -pathtype leaf) {
                $existinghtml = gc "release\$pagehref"

                if ((compare-object $existinghtml $pagehtml | measure-object).count -gt 0) {
        	        $pagehtml | sc "release\$pagehref"
                    write-host "$pagehref updated"
                } else {
                    write-host "$pagehref unchanged"
                }
            } else {
                $pagehtml | sc "release\$pagehref"
       	        write-host "$pagehref created"
            }
	    }
    }
}

start "release\index.html"
