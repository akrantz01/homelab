"""
AWS SSM Parameter Store SDB Module

:maintainer:    Alex Krantz
:maturity:      new
:platform:      all
:depends:       boto3

This module allows access to AWS SSM Parameter Store using an ``sdb://`` URI.
"""

__func_alias__ = {"set_": "set"}

def set_(key, value, profile=None):
  """
  Set a key/value pair in the AWS SSM Parameter Store
  """
  return True


def get(key, profile=None):
  """
  Get a value from the AWS SSM Parameter Store
  """
  return True


def delete(key, profile=None):
  """
  Delete a key from AWS SSM Parameter Store
  """
  return True
