import logging
import re
import sys
import yaml

log = logging.getLogger(__name__)

class ConfigFile:
    def __init__(self):
        self.data = {}
        self.regex = re.compile(r'({{([^{}]*)}})')

    def open(self, fname):
        log.debug("opening "+fname)
        with open(fname) as f:
            self.data = yaml.safe_load(f.read())
    
    def __evaluate_dict(self, x):
        ret = {}
        for k in x.keys():
            ret[k] = self.__evaluate(x[k])
        return ret

    def __evaluate_list(self, x):
        return [ self.__evaluate(v) for v in x ]

    def __evaluate(self, input):
        if type(input) == dict:
            return self.__evaluate_dict(input)
        elif type(input) == list:
            return self.__evaluate_list(input)
        elif type(input) == str:
            return self.__process_value(input)
        else:
            return input

    def preprocess(self):
        res = self.__evaluate(self.data)
        return res

    def read_keys(self, v):
        log.debug("read_keys (enter): " + v)

        try:
            it = self.data
            for x in v.split('.'):
                it = it[x]
        except KeyError:
            log.error("read_keys : "+v+" not in config")
            sys.exit(1)
        
        if type(it) is not dict:
            log.error("read_keys : "+v+" is not a dict")
        
        keys = list(it.keys())
        log.debug("read_keys (exit): keys("+v+")="+",".join(keys))
        return keys

    def read_value(self, v, default=None):
        log.debug("read_value (enter): " + v)

        try:
            it = self.data
            for x in v.split('.'):
                it = it[x]
        except KeyError:
            if default is not None:
                res = default
            else:
                log.error("read_value : "+v+" not in config")
                sys.exit(1)
        
        def repl(match):
            return str(self.__process_value(match.group()[2:-2]))
    
        if type(it) == str:
            it = self.regex.sub(lambda m: str(self.__process_value(m.group()[2:-2])), it)
        
        if type(it) is str:
            res = self.__process_value(it)
        else:
            res = it

        log.debug("read_value (exit): "+v+"="+str(res))

        return res

    def __process_value(self, v):
        log.debug("process_value (enter): "+str(v))
        
        parts = v.split('.')
        prefix = parts[0]

        if prefix == "variables":
            res = self.read_value(v)
        else:
            res = v
        
        log.debug("process_value (exit): "+str(v)+"="+str(res))
        return res
