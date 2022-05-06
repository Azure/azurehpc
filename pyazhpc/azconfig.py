import json
import os
import re
import sys

import azlog
import azutil

log = azlog.getLogger(__name__)

class ConfigFile:
    def __init__(self):
        self.file_location = '.'
        self.data = {}
        self.regex = re.compile(r'({{([^{}]*)}})')

    def open(self, fname):
        log.debug("opening "+fname)
        self.file_location = os.path.dirname(fname)
        if self.file_location == "":
            self.file_location = "."
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
            elif self.read_value(f"vnet.gateway.name", False):
                dest = azutil.get_vm_private_ip(self.read_value("resource_group"), f"{install_from}")
        log.debug(f"install_from destination : {dest}")
        return dest
    
    def __evaluate_dict(self, x, extended):
        ret = {}
        for k in x.keys():
            ret[k] = self.__evaluate(x[k], extended)
        return ret

    def __evaluate_list(self, x, extended):
        return [ self.__evaluate(v, extended) for v in x ]

    def __evaluate(self, input, extended=True):
        if type(input) == dict:
            return self.__evaluate_dict(input, extended)
        elif type(input) == list:
            return self.__evaluate_list(input, extended)
        elif type(input) == str:
            fname = self.file_location + "/" + input[1:]
            if input.startswith("@") and os.path.isfile(fname) and fname.endswith(".json"):
                log.debug(f"loading include {fname}")
                with open(fname) as f:
                    input = json.load(f)
                return self.__evaluate_dict(input, extended)
            else:
                return self.process_value(input, extended)
        else:
            return input

    def preprocess(self, extended=True):
        res = self.__evaluate(self.data, extended)
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
                if type(it) is str:
                    fname = self.file_location + "/" + it[1:]
                    if it.startswith("@") and os.path.isfile(fname) and fname.endswith(".json"):
                        log.debug(f"loading include {fname}")
                        with open(fname) as f:
                            it = json.load(f)
                    else:
                        log.error("invalid path in config file ({v})")
                it = it[x]
            
            if type(it) is str:
                res = self.process_value(it)
            else:
                res = it
        except KeyError:
            log.debug(f"using default value ({default})")
            res = default
        
        log.debug("read_value (exit): "+v+"="+str(res))

        return res

    def process_value(self, v, extended=True):
        log.debug(f"process_value (enter): {v} [extended={extended}]")

        def repl(match):
            return str(self.process_value(match.group()[2:-2], extended))
    
        v = self.regex.sub(lambda m: str(self.process_value(m.group()[2:-2], extended)), v)
        
        parts = v.split('.')
        prefix = parts[0]
        if len(parts) == 1:
            prefix = ""

        if prefix == "variables":
            res = self.read_value(v)
        elif prefix == "secret":
            res = azutil.get_keyvault_secret(parts[1], parts[2])
        elif prefix == "image":
            res = azutil.get_image_id(parts[1], parts[2])
        elif extended and prefix == "sasurl":
            log.debug(parts)
            url = azutil.get_storage_url(parts[1])
            x = parts[-1].split(",")
            if len(x) == 1:
                perm = "r"
                dur = "2h"
            elif len(x) == 2:
                perm = x[1]
                dur = "2h"
                parts[-1] = x[0]
            else:
                perm = x[1]
                dur = x[2]
                parts[-1] = x[0]
            container = x[0].split('/')[0]
            saskey = azutil.get_storage_saskey(parts[1], container, perm, dur)
            log.debug(parts)
            path = ".".join(parts[2:])
            res = f"{url}{path}?{saskey}"
        elif extended and prefix == "fqdn":
            res = azutil.get_fqdn(self.read_value("resource_group"), parts[1]+"_pip")
        elif extended and prefix == "sakey":
            res = azutil.get_storage_key(parts[1])
        elif extended and prefix == "saskey":
            x = parts[-1].split(",")
            if len(x) == 1:
                perm = "r"
                dur = "2h"
            elif len(x) == 2:
                perm = x[1]
                dur = "2h"
            else:
                perm = x[1]
                dur = x[2]
            container = x[0].split('/')[0]
            res = azutil.get_storage_saskey(parts[1], container, perm, dur)
        elif extended and prefix == "laworkspace":
            res = azutil.get_log_analytics_workspace(parts[1], parts[2])
        elif extended and prefix == "lakey":
            res = azutil.get_log_analytics_key(parts[1], parts[2])
        elif extended and prefix == "acrkey":
            res = azutil.get_acr_key(parts[1])
        else:
            # test to see if we are including a files contents (e.g. for customData)
            fname = self.file_location + "/" + v[1:]
            if v.startswith("@") and os.path.isfile(fname):
                log.debug(f"loading text include {fname}")
                with open(fname) as f:
                    res = f.read()
            else:
                res = v
        
        log.debug("process_value (exit): "+str(v)+"="+str(res))
        return res
