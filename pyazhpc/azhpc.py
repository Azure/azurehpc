import argparse
import json
import logging
import time

import arm
import azconfig
import azutil

log = logging.getLogger(__name__)

def do_preprocess(args):
    log.info("reading config file ({})".format(args.config_file))
    config = azconfig.ConfigFile()
    config.open(args.config_file)
    print(json.dumps(config.preprocess(), indent=4))

def do_deploy(args):
    log.info("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    config = c.preprocess()
    tpl = arm.ArmTemplate()
    tpl.read(config)

    log.info("writing out arm template to " + args.output_template)
    with open(args.output_template, "w") as f:
        f.write(tpl.to_json())

    log.info("creating resource group " + config["resource_group"])
    azutil.create_resource_group(
        config["resource_group"],
        config["location"]
    )
    log.info("deploying arm template")
    azutil.deploy(
        config["resource_group"],
        args.output_template
    )

def do_destroy(args):
    log.info("reading config file ({})".format(args.config_file))
    config = azconfig.ConfigFile()
    config.open(args.config_file)

    log.warning("deleting entire resource group ({})".format(config.read_value("resource_group")))
    if not args.no_wait:
        log.info("you have 10s to change your mind and ctrl-c!")
        time.sleep(10)
        log.info("too late!")

    azutil.delete_resource_group(
        config.read_value("resource_group")
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config-file", "-c", type=str, 
        default="config.json", help="config file"
    )
    parser.add_argument(
        "-v", "--verbose", 
        help="increase output verbosity",
        action="store_true"
    )

    subparsers = parser.add_subparsers(help="actions")

    preprocess_parser = subparsers.add_parser(
        "preprocess", 
        parents=[parser],
        add_help=False,
        description="preprocess the config file",
        help="expand all the config macros"
    )
    preprocess_parser.set_defaults(func=do_preprocess)

    deploy_parser = subparsers.add_parser(
        "deploy", 
        parents=[parser],
        add_help=False,
        description="deploy the config",
        help="create an arm template and deploy"
    )
    deploy_parser.set_defaults(func=do_deploy)
    deploy_parser.add_argument(
        "--output-template", 
        "-o", 
        type=str, 
        default="deploy.json", 
        help="filename for the arm template",
    )

    destroy_parser = subparsers.add_parser(
        "destroy", 
        parents=[parser],
        add_help=False,
        description="delete the resource group",
        help="delete entire resource group"
    )
    destroy_parser.set_defaults(func=do_destroy)
    destroy_parser.add_argument(
        "--no-wait", 
        action="store_true", 
        help="delete resource group immediately"
    )
    
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG, format='%(asctime)s:%(filename)s:%(lineno)d:%(levelname)s:%(message)s')
    else:
        logging.basicConfig(level=logging.INFO, format='%(asctime)s:%(levelname)s:%(message)s')

    log.debug(args)

    args.func(args)

    log.info("exiting")

