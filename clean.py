#!/usr/bin/env python

import shutil, re, os

def Clean():
    goonjDir = os.path.expanduser('~/Library/Application Support/Goonj/')
    goonjPlist = os.path.expanduser('~/Library/Preferences/org.GoonjProject.Goonj.plist')
    shutil.rmtree(goonjDir)
    os.remove(goonjPlist)

if __name__ == '__main__':
    Clean()
