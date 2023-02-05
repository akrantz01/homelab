"""
AWS SSM Parameter Store SDB Module

:maintainer:    Alex Krantz
:maturity:      new
:platform:      all
:depends:       boto3

This module allows access to AWS SSM Parameter Store using an ``sdb://`` URI.
"""

import logging

import salt.utils.versions
from salt.exceptions import SaltConfigurationError

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


def _session(profile):
  """
  Return the boto3 session to use for the SSM client.

  If profile:profile_name is set in the salt configuration, use that profile.
  Otherwise, fall back on the default AWS profile.

  We use the boto3 profile system to avoid having to duplicate
  individual boto3 configuration settings in salt configuration.
  """
  profile_name = profile.get("profile", None)
  if profile_name:
    log.info('Using the "%s" boto3 profile.', profile_name)
  else:
    log.info("Using the default boto3 profile.")
  
  try:
    return boto3.Session(profile_name=profile_name)
  except botocore.exceptions.ProfileNotFound as e:
    raise SaltConfigurationError(
      'Boto3 could not find the "{}" profile configured in Salt.'.format(profile_name or "default")
    ) from e
  except botocore.exceptions.NoRegionError as e:
    raise SaltConfigurationError(
      "Boto3 was unable to determine the AWS endpoint region using the {} profile.".format(profile_name or "default")
    ) from e


def _ssm(profile):
  """
  Return the boto3 client for the SSM API.
  """
  session = _session(profile)
  return session.client("ssm")


def set_(key, value, profile=None):
  """
  Set a key/value pair in the AWS SSM Parameter Store
  """
  ssm = _ssm(profile)
  
  key_id = profile.get("key", "alias/aws/ssm")

  try:
    ssm.put_parameter(
      Name=_name(key, profile),
      Value=value,
      Type="SecureString",
      KeyId=key_id,
      Overwrite=True,
      Tier=profile.get("tier", "Standard"),
      Tags=_tags(profile),
    )

    return True
  except botocore.exceptions.ClientError as e:
    error_code = e.response.get("Error", {}).Get("Code", "")

    if error_code == "InvalidKeyId":
      raise SaltConfigurationError(
        'The key ID "{}" was not found in AWS KMS.'.format(key_id)
      ) from e
    
    raise


def get(key, profile=None):
  """
  Get a value from the AWS SSM Parameter Store
  """
  print(key)
  print(profile)
  return key


def delete(key, profile=None):
  """
  Delete a key from AWS SSM Parameter Store
  """
  return True


def _name(key, profile):
  """
  Return the prefix for the SSM Parameter Store
  """
  prefix = profile.get("prefix", "/salt").split("/")
  name = key.split("/")

  return "/".join(prefix + name)

def _tags(profile):
  """
  Return the tags to use for the SSM Parameter Store
  """
  tags = profile.get("tags", {})
  return [{"Key": k, "Value": v} for k, v in tags.items()]
