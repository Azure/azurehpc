import json
import re
import sys

import azlog
import azutil

log = azlog.getLogger(__name__)

class ConfigFile:
    def __init__(self):
        self.data = {}
        self.regex = re.compile(r'({{([^{}]*)}})')

    def open(self, fname):
        log.debug("opening "+fname)
        with open(fname) as f:
            self.data = json.load(f)
    
    def save(self, fname):
        with open(fname, "w") as f:
            json.dump(self.data, f, indent=4)

    def get_install_from_destination(self):
        install_from = self.read_value("install_from")
        dest = install_from
        if install_from:
            if self.read_value(f"resources.{install_from}.public_ip", False):
                dest = azutil.get_fqdn(self.read_value("resource_group"), f"{install_from}_pip")
        log.debug(f"install_from destination : {dest}")
        return dest

    def get_unset_vars(self):
        return [ 
            x 
            for x in self.data.get("variables", {}).keys() 
            if self.data["variables"][x] == "<NOT-SET>"
        ]

    def replace_vars(self, vdict):
        if "variables" in self.data:
            for v in vdict.keys():
                if v in self.data["variables"]:
                    self.data["variables"][v] = vdict[v]

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
            
            if type(it) is str:
                res = self.__process_value(it)
            else:
                res = it
        except KeyError:
            log.debug(f"using default value ({default})")
            res = default
        
        log.debug("read_value (exit): "+v+"="+str(res))

        return res

    def __process_value(self, v):
        log.debug("process_value (enter): "+str(v))

        def repl(match):
            return str(self.__process_value(match.group()[2:-2]))
    
        v = self.regex.sub(lambda m: str(self.__process_value(m.group()[2:-2])), v)
        
        parts = v.split('.')
        prefix = parts[0]

        if prefix == "variables":
            res = self.read_value(v)
        elif prefix == "secret":
            res = azutil.get_keyvault_secret(parts[1], parts[2])
        elif prefix == "sasurl":
            log.debug(parts)
            url = azutil.get_storage_url(parts[1])
            x = parts[-1].split(",")
            if len(x) == 1:
                perm = "r"
            else:
                perm = x[1]
                parts[-1] = x[0]
            container = parts[2].split('/')[0]
            saskey = azutil.get_storage_saskey(parts[1], container, perm)
            log.debug(parts)
            path = ".".join(parts[2:])
            res = f"{url}{path}?{saskey}"
        elif prefix == "fqdn":
            res = azutil.get_fqdn(self.read_value("resource_group"), parts[1]+"_pip")
        elif prefix == "sakey":
            res = azutil.get_storage_key(parts[1])
        elif prefix == "saskey":
            x = parts[2].split(",")
            if len(x) == 1:
                x.append("r")
            container = x[0].split('/')[0]
            res = azutil.get_storage_saskey(parts[1], container, x[1])
        elif prefix == "laworkspace":
            res = azutil.get_log_analytics_workspace(parts[1], parts[2])
        elif prefix == "lakey":
            res = azutil.get_log_analytics_key(parts[1], parts[2])
        elif prefix == "acrkey":
            res = azutil.get_acr_key(parts[1])
        else:
            res = v
        
        log.debug("process_value (exit): "+str(v)+"="+str(res))
        return res
