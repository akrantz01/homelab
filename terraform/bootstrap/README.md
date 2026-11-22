# Bootstrapping

A subproject used to bootstrap the initial infrastructure. Requires elevated permissions to deploy.

This project can only be applied locally and is always skipped by `terragrunt --all run`.

<table>
    <thead>
        <tr>
            <th>Provider</th>
            <th>Permissions</th>
            <th>Instructions</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>GitHub</td>
            <td>
                <ul>
                    <li>Actions: read</li>
                    <li>Administration: write</li>
                    <li>Environments: write</li>
                    <li>Secrets: write</li>
                </ul>
            </td>
            <td>
                Create a new <a href="https://github.com/settings/personal-access-tokens/new?name=Homelab+Bootstrap&target_name=akrantz01&description=Used+for+bootstrapping+my+homelab+infrastructure+from+https%3A%2F%2Fgithub.com%2Fakrantz01%2Fhomelab&expires_in=30&administration=write&actions=read&secrets=write&actions_variables=write&environments=write">fine-grained access token</a> and export the <code>GITHUB_TOKEN</code> environment variable.
            </td>
        </tr>
    </tbody>
</table>
