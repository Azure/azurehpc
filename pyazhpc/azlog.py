import logging

debug = False
color = True

grey = "\x1b[38;21m"
bold_grey = "\x1b[38;1m"
green = "\x1b[32;21m"
bold_green = "\x1b[32;1m"
yellow = "\x1b[33;21m"
bold_yellow = "\x1b[33;1m"
red = "\x1b[31;21m"
bold_red = "\x1b[31;1m"
reset = "\x1b[0m"

regular_format = {
    logging.DEBUG: "[%(asctime)s] debug: %(message)s",
    logging.INFO: "[%(asctime)s] info: %(message)s",
    logging.WARNING: "[%(asctime)s] warning: %(message)s",
    logging.ERROR: "[%(asctime)s] error: %(message)s",
    logging.CRITICAL: "[%(asctime)s] critical: %(message)s"
}

regular_debug_format = {
    logging.DEBUG: "[%(asctime)s] debug: %(message)s (%(name)s %(filename)s:%(lineno)d)",
    logging.INFO: "[%(asctime)s] info: %(message)s (%(name)s %(filename)s:%(lineno)d)",
    logging.WARNING: "[%(asctime)s] warning: %(message)s (%(name)s %(filename)s:%(lineno)d)",
    logging.ERROR: "[%(asctime)s] error: %(message)s (%(name)s %(filename)s:%(lineno)d)",
    logging.CRITICAL: "[%(asctime)s] critical: %(message)s (%(name)s %(filename)s:%(lineno)d)"
}

color_format = {
    logging.DEBUG: grey + "[%(asctime)s] " + bold_grey + "%(message)s" + reset,
    logging.INFO: green + "[%(asctime)s] " + bold_green + "%(message)s" + reset,
    logging.WARNING: yellow + "[%(asctime)s] warning: " + bold_yellow + "%(message)s" + reset,
    logging.ERROR: red + "[%(asctime)s] error: " + bold_red + "%(message)s" + reset,
    logging.CRITICAL: red + "[%(asctime)s] critical: " + bold_red + "%(message)s" + reset
}

color_debug_format = {
    logging.DEBUG: grey + "[%(asctime)s] " + bold_grey + "%(message)s" + grey + " (%(name)s %(filename)s:%(lineno)d)" + reset,
    logging.INFO: green + "[%(asctime)s] " + bold_green + "%(message)s" + green + " (%(name)s %(filename)s:%(lineno)d)" + reset,
    logging.WARNING: yellow + "[%(asctime)s] warning: " + bold_yellow + "%(message)s" + yellow + " (%(name)s %(filename)s:%(lineno)d)" + reset,
    logging.ERROR: red + "[%(asctime)s] error: " + bold_red + "%(message)s" + red + " (%(name)s %(filename)s:%(lineno)d)" + reset,
    logging.CRITICAL: red + "[%(asctime)s] critical: " + bold_red + "%(message)s" + red + " (%(name)s %(filename)s:%(lineno)d)" + reset
}

class CustomFormatter(logging.Formatter):
    def format(self, record):
        if color:
            if debug:
                log_fmt = color_debug_format.get(record.levelno)
            else:
                log_fmt = color_format.get(record.levelno)
        else:
            if debug:
                log_fmt = regular_debug_format.get(record.levelno)
            else:
                log_fmt = regular_format.get(record.levelno)
            
        formatter = logging.Formatter(log_fmt, "%Y-%m-%d %H:%M:%S")
        
        return formatter.format(record)

custom_handler = logging.StreamHandler()
custom_handler.setFormatter(CustomFormatter())


all_loggers = []

def getLogger(name):
    global all_loggers, custom_handler, debug
    log = logging.getLogger(name)
    log.addHandler(custom_handler)
    if debug:
        log.setLevel(logging.DEBUG)
    else:
        log.setLevel(logging.INFO)
    all_loggers.append(log)
    return log

def setDebug(b):
    global debug
    debug = b
    if debug:
        for log in all_loggers:
            log.setLevel(logging.DEBUG)
    else:
        for log in all_loggers:
            log.setLevel(logging.INFO)

def setColor(b):
    global color
    color = b