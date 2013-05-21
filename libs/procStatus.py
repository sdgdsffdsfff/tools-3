#!/bin/env python

import sys
from os import popen

def test():
    status = procStatus.status()
    if status > 1 :
       print "Exit: %d; is running;" % (status)
       sys.exit(status)

class procStatus(object):
    def __init__(self, function):
        print("__init__() called")
        self.f = function

    @staticmethod
    def status():
        _tmp = ""
        _name = ""
        if len(sys.argv) == 1 :
            _name = str(sys.argv[0])
        else:
            for s in sys.argv:
                _tmp += s + "\\s+"
            #    _name += s + " "
            _name = _tmp[0:-3]
        _pid_cmd = "ps -ef|grep -P '" + _name + "'|grep -v grep"
        _pid = popen( _pid_cmd ).readlines()
        return len(_pid)

if __name__ == "__main__":
    pass #TODO: test
