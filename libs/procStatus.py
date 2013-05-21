#!/bin/env python

import sys
from os import popen

def test():
    proc = procStatus()
    status = proc.status()
    if status > 1 :
       print "Exit: %d;  %s is running;" % (status, prog.name)
       sys.exit(status)

class procStatus(object):
    def __init__(self):
        _tmp = ""
        self.name = ""
        if len(sys.argv) == 1 :
            self.name = str(sys.argv[0])
            self._name = str(sys.argv[0])
        else:
            for s in sys.argv:
                _tmp += s + "\\s+"
                self.name += s + " "
            self._name = _tmp[0:-3]

    def __getitem__(self, name):
        return getattr(self, name)

    def status(self):
        _pid_cmd = "ps -ef|grep -P '" + self._name + "'|grep -v grep"
        _pid = popen( _pid_cmd ).readlines()
        return len(_pid)

if __name__ == "__main__":
    pass #TODO: test
