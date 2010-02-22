#!/usr/bin/env python

import shutil, os, sys

def Clean():
    goonjDir = os.path.expanduser('~/Library/Application Support/Goonj/')
    goonjPlist = os.path.expanduser('~/Library/Preferences/org.GoonjProject.Goonj.plist')
    
    if len(sys.argv) == 1:
        shutil.rmtree(goonjDir)
        os.remove(goonjPlist)
    elif sys.argv[1] == 'trackdb':
        trackDb = os.path.join(goonjDir, 'tracks.db')
        os.remove(trackDb)

if __name__ == '__main__':
    Clean()
