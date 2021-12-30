'Login as: {0}' -f (cat release/userid)
'FTP commands after login:'
''
'cd ddrs.org.uk'
'lcd ftp'
'prompt'
'mput *'
'bye'
''
'If successful: rm ftp/*'

ftp ddrs.org.uk

