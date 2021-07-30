-- vim:ft=lua:ts=2:sw=2:sts=2
dofile(os.getenv('IMAPFILTER_HOME')..'/cfg/default.lua')
acc = IMAP {
  server = 'imap.gmail.com',
  -- port = 993,
  username = 'user',
  password = get_acc_passwd('user'),
  -- DEPRECATED:('ssl3'): insecure
  -- ALSO: latest openssl -> 'auto' -> negotiate mutually highest
  ssl = 'tls1.2',
}
inbox = acc['INBOX']:select_all()
---------------------------------------------

mv_from(acc, inbox, 'it/maint', {
  'maintenance@company.com',
})
mv_subj_any(acc, inbox, 'work/reports', {'send weekly reports'})
