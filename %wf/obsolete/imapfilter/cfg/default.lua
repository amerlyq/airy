-- vim:ft=lua:ts=2:sw=2:sts=2
dofile(os.getenv('IMAPFILTER_HOME')..'/cfg/general.lua')
dofile(os.getenv('IMAPFILTER_HOME')..'/cfg/filters.lua')

-- SEE $ man imapfilter_config
options.create = false    -- create mailbox only if received hint from server
options.starttls = true   -- prefer tls over ssl
options.subscribe = true  -- set new mailboxes as active to be recognized
options.timeout = 30      -- wait server response
-- options.charset = 'UTF-8'
