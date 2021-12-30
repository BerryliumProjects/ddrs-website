
perl .\buildpages.pl
$pwdurl = 'file:{0}/release/index.html' -f ($pwd -replace '\\','/')

start firefox $pwdurl

