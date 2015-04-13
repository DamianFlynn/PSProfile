# Description
Powershell Profile and Support Modules.
The main purpose of the repositiory is to act a single reference source to the profile which I will use from multiple different servers, in different environments.

# Install
To install the profile including all modules you can just run in a PowerShell v3 the following command:
<pre>
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
</pre>

## Configure GIT
```PowerShell
git config --global user.email "info@damianflynn.com"
git config --global user.name "Damian Flynn"
```

## Checkout the Repo
```PowerShell
git init
git remote add origin https://github.com/DamianFlynn/PSProfile.git
git fetch
git checkout -t origin/master --force
```