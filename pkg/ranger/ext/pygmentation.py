#!/usr/bin/env python
# vim: fileencoding=utf-8

# import os
import sys
import re
import mimetypes
import pygments


def check_modeline(fpath):
    fts = {"plain": "plain"}
    vimft = "plain"

    pattern = re.compile("^\S+\s+vim:.*ft=(\w+)")
    with open(fpath) as f:
        for line in f.readlines(10):
            match = pattern.match(line)
            if match:
                vimft = match.group(1)
                break

    return fts.get(vimft, "plain")


def main():
    fpath = sys.argv[1]
    mime = mimetypes.guess_type(fpath, strict=False)

    """
    Return a Lexer subclass instance that has mime in its mimetype list. The
    lexer is given the options at its instantiation.
    """
    try:
        lexer = pygments.lexers.get_lexer_for_mimetype(mime)
    except pygments.util.ClassNotFound:
        lexer = check_modeline(fpath)

    return lexer


if __name__ == '__main__':
    # sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    lexer = main()
    # os.path.realpath('pygmentize')
    # pygmentize -g -O style=colorful,linenos=1
    sys.argv = [sys.argv[0], sys.argv[1]]
    sys.exit(pygments.cmdline.main())
