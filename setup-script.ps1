# variables
param(
    [string]$pythonVersion = "3.7.4",
    [string]$nodeVersion = "",
    [string]$JDKVersion = "12.0.1",
    [string]$gitVersion = "2.22.0",
    [switch]$verbose,
    [switch]$deleteInstallers
    )

class Dependency {
    [string]$url
    [array]$arguments
    [string]$fileExtension
    [bool]$shouldInstall = $true

    Dependency(
        [string]$url
    ){
        [Dependency]::new($url, @(), ".exe")
    }

    Dependency(
        [string]$url,
        [array]$arguments
    ){
        [Dependency]::new($url, $arguments, ".exe")
    }

    Dependency(
        [string]$url,
        [array]$arguments,
        [string]$fileExtension
    ){
        $this.url = $url
        $this.arguments = $arguments
        $this.fileExtension = $fileExtension
    }

    [void]setInstall([bool]$install){
        $this.shouldInstall = $install
    }

}

$deps= @{
    "python" = [Dependency]::new(("https://www.python.org/ftp/python/{0}/python-{0}.exe" -f $pythonVersion), ("/quiet","PrependPath=1","Include_test=0"))
    "JDK" = [Dependency]::new(("https://download.oracle.com/otn-pub/java/jdk/{0}+12/69cfe15208a647278a19ef0990eea691/jdk-{0}_windows-x64_bin.exe" -f $JDKVersion),("INSTALL_SILENT=1"))
    "VSCode" = [Dependency]::new("https://go.microsoft.com/fwlink/?LinkID=534107")
    "git" = [Dependency]::new("https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe")
}


#TODO - Add version check

#file downloads
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11"


$client = New-Object System.Net.WebClient
foreach($key in $deps.keys)
{
    if ($deps[$key].shouldInstall) {
        try {
            $client.DownloadFile($deps[$key].url, ("./{0}{1}}" -f ($key, $deps[$key].fileExtension)))
            if ($verbose.IsPresent) {
                Write-Output ("{0} has been installed from url {1}" -f ($key, $deps[$key].url))
            }    
        }
        catch {
            if ($verbose.IsPresent) {
                Write-Output ("error encountered while trying to install {0} from {1}" -f ($key, $deps[$key].url))
            }
        }    
    } else {
        Write-Output "$key is already installed"
    }
    
}

Write-Output "Installers downloaded"


#installation
foreach ($key in $deps.keys) {
    if ($deps[$key].shouldInstall) {
        Start-Process -FilePath  ("./$key" + $deps[$key].fileExtension) -ArgumentList $deps[$key].arguments
    }
}

#wait for installations to end
Get-Job | Wait-Job


#adding JAVA_HOME to path
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-$JDKVersion", "User")
[System.Environment]::SetEnvironmentVariable("PATH", $env:Path + ";$env:JAVA_HOME\bin", "User")


#delete installers
if ($deleteInstallers.IsPresent) {
    foreach ($key in $deps.keys) {
        if ($deps[$key].shouldInstall) {
            Remove-Item "./$key"
        }
    }
}


#TODO - Add vscode extension installation