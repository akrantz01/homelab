"""
AWS SSM Parameter Store SDB Module

:maintainer:    Alex Krantz
:maturity:      new
:platform:      all
:depends:       boto3

This module allows access to AWS SSM Parameter Store using an ``sdb://`` URI.
"""

import logging

import salt.exceptions

try:
  import boto3
  import botocore.exceptions

  logging.getLogger("boto3").setLevel(logging.CRITICAL)
except ImportError:
  pass

log = logging.getLogger(__name__)

__func_alias__ = {"set_": "set"}

def __virtual__():
  """
  Only load if boto3 libraries exist and if boto libraries are greater than
  a given version.
  """
  return salt.utils.versions.check_boto_reqs()

def set_(key, value, profile=None):
  """
  Set a key/value pair in the AWS SSM Parameter Store
  """
  return True


def get(key, profile=None):
  """
  Get a value from the AWS SSM Parameter Store
  """
  log.info(key)
  log.info(profile)
  return True


def delete(key, profile=None):
  """
  Delete a key from AWS SSM Parameter Store
  """
  return True
