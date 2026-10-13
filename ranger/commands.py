## MOVED: (class -> plugin)
##   ag                                      -> plugins/cmd_ag.py
##   doc                                     -> plugins/cmd_doc.py
##   cd_shelldir cd_gitroot cda (+cd_samedur)-> plugins/cmd_cd.py
##   nrenum (+rename_clip)                   -> plugins/cmd_rename.py
##   actualee                                -> plugins/cmd_actualee.py
##   console edit mkdircd (+reload_rc)       -> plugins/cmd_cli.py
##   flat_inode unfilter (+toggle_preview_images sort_reset view_duration) -> plugins/cmd_view.py
##   mvsel link_orig (+paste_relink paste_flatlink) -> plugins/cmd_xfer.py
##   avfs_left avfs_right (new)              -> plugins/cmd_avfs.py
##   today_date tmpfile, Protocols, TypeAliases -> plugins/rutil.py
##
## DEBUG: command unknown after the split? -> :eval fm.commands.commands.keys() ; check ~/.config/ranger/plugins/__init__.py
