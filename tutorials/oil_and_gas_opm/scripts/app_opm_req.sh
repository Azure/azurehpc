#!/bin/bash

packages()
{
  sudo yum install -y epel-release
  sudo yum install -y lapack lapack-devel
}

packages
