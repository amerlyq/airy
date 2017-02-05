#!/usr/bin/env python
# vim: fileencoding=utf-8

class _Parser_xml:
    def __init__(self, ntg=['title']):
        self.tag_stack = []
        self.node_stack = []
        self.NODE_TAGS = ntg

    def start(self, tag, attrib):
        print(" " * len(self.tag_stack) + "<" + tag + ">")
        self.tag_stack.append(tag)
        if tag in self.NODE_TAGS:
            self.ptr = tag
            self.node_stack.append(self.ptr)

    def end(self, tag):
        self.tag_stack.pop()
        if tag in self.NODE_TAGS:
            self.ptr = self.node_stack.pop()
        print(" " * len(self.tag_stack) + "</" + tag + ">")

    def data(self, data):
        print("-" * len(self.tag_stack) + '"' + data + '"' + " : " +
                "/".join(self.tag_stack))

    def close(self):
        pass

import sys
import re
from xml.etree.ElementTree import XMLParser

def main():
    if 1 < len(sys.argv):  # .xml file path in $1 argument, else use /dev/stdin
        path = sys.argv[1]
        text = open(path).read()
    else:
        text = "\n".join(sys.stdin.readlines())
    ntg = sys.argv[2] if 2 < len(sys.argv) else None

    parser = XMLParser(target=_Parser_xml(ntg))
    text = re.sub('\\sxmlns="[^"]+"', '', text, count=1)
    parser.feed(text)
    parser.close()

if __name__ == '__main__':
    main()

