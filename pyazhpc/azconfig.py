import logging
import yaml

class ConfigFile:
    def __init__(self):
        self.data = {}

    def open(self, fname):
        logging.debug("opening "+fname)
        with open(fname) as f:
            self.data = yaml.safe_load(f.read())
        
    def read_value(self, v):
        logging.debug("reading " + v)
        it = self.data
        for x in v.split('.'):
            it = it[x]
        res = self.__process_value(it)
        return res

    def __process_value(self, v):
        if type(v) is not str:
            return v
        parts = v.split('.')
        prefix = parts[0]

        if prefix == "variables":
            res = self.read_value(v)
        else:
            res = v
        
        return res

