from typing import Optional

from cachetools.func import ttl_cache
from salt import config
from salt.client import LocalClient
from salt.runner import RunnerClient

from .config import SECRET_TTL

_local = LocalClient("/etc/salt/master")
_runner = RunnerClient(config.master_config("/etc/salt/master"))


@ttl_cache(ttl=SECRET_TTL)
def secret(key: str, backend: str = "secrets") -> Optional[str]:
    """
    Get a secret from SaltStack, cached for 15 minutes.
    """
    arg = f"sdb://{backend}/{key}"
    result = _runner.cmd("sdb.get", [arg])

    # Handles the case where the backend is not configured.
    if result == arg:
        return None
    return result


def sync():
    """
    Sync the SaltStack fileserver backend and modules
    """

    _runner.cmd("fileserver.update")
    _runner.cmd("saltutil.sync_all")


def apply() -> bool:
    """
    Apply the SaltStack highstate
    """

    jid = _local.cmd_async("*", "state.apply")
    return jid != 0
