$GitURL = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140611/Git-1.9.4-preview20140611.exe"
$PythonURL = "https://www.python.org/ftp/python/2.7.8/python-2.7.8.msi"
$PyCryptoURL = "http://www.voidspace.org.uk/downloads/pycrypto26/pycrypto-2.6.win32-py2.7.exe"
$PyWin32URL = "https://www.dropbox.com/s/fb7mope55krm8wu/pywin32-219.win32-py2.7.exe?dl=1"
$MySQLPythonURL = "https://www.dropbox.com/s/kwit99l20olm698/MySQL-python-1.2.5.win32-py2.7.exe?dl=1"

$CinderRepoURL = "https://github.com/openstack/cinder.git"
$WinRMScriptURL = "https://raw.githubusercontent.com/petrutlucian94/windows-openstack-imaging-tools/master/SetupWinRMAccess.ps1"
$MinGWURL = "https://www.dropbox.com/s/jpxnc4ypesv90cv/MinGW.zip?dl=1"
$qemuURL = "https://www.dropbox.com/s/11zvb1468s6v0hs/qemu-img.zip?dl=1"

function unzip($src, $dest) {

	$shell = new-object -com shell.application
	$zip = $shell.NameSpace($src)
	foreach($item in $zip.items())
	{
		$shell.Namespace($dest).copyhere($item)
	}

}

#git install
echo "Installing git"

$dest = "$env:temp\Git-1.9.4-preview20140611.exe"
(New-Object System.Net.WebClient).DownloadFile($GitURL, $dest)

& $dest /SILENT | Out-Null


$env:Path = $env:Path + ";C:\Program Files (x86)\Git\cmd"
setx PATH $env:Path

#python27 install
echo "Installing Python 2.7"

$dest = "$env:temp\python-2.7.8.msi"
(New-Object System.Net.WebClient).DownloadFile($PythonURL, $dest)

msiexec /i $dest /qb ALLUSERS=1 | Out-Null

$env:Path = $env:Path + ";C:\Python27\;C:\Python27\Scripts"
setx PATH $env:Path

#easy_install install
echo "Installing easy_install"

(Invoke-WebRequest https://bootstrap.pypa.io/ez_setup.py).Content | python -

#pip install
echo "Installing pip"

easy_install pip

#install mingw
echo "Installing MinGW"

$MinGWFolder = "C:\"
#mkdir $MinGWFolder

$MinGWZip = "$env:temp\MinGW.zip"
(New-Object System.Net.WebClient).DownloadFile($MinGWURL, $MinGWZip)
unzip $MinGWZip $MinGWFolder

$env:Path = $env:Path + ";C:\MinGW\bin;C:\MinGW\mingw32\bin;C:\MinGW\msys\1.0\bin;C:\MinGW\msys\1.0\sbin"
setx PATH $env:Path

#install qemu
echo "Installing qemu-img"

$qemuFolder = "C:\"

$qemuZip = "$env:temp\qemu-img.zip"
(New-Object System.Net.WebClient).DownloadFile($qemuURL, $qemuZip)
unzip $qemuZip $qemuFolder

$env:Path = $env:Path + ";C:\qemu-img\"
setx PATH $env:Path

#install pywin32
echo "Installing pywin32-219.win32-py2.7"

$dest = "$env:temp\pywin32-219.win32-py2.7.exe"
(New-Object System.Net.WebClient).DownloadFile($PyWin32URL, $dest)
easy_install $dest

#install pycrypto
echo "Installing pycrypto"

easy_install $PyCryptoURL

#install MySQL-Python
echo "Installing MySQL-python-1.2.5.win32-py2.7"

$dest = "$env:temp\MySQL-python-1.2.5.win32-py2.7.exe"
(New-Object System.Net.WebClient).DownloadFile($MySQLPythonURL, $dest)
easy_install $dest

pip install ecdsa
pip install pbr
pip install amqp
pip install wmi

#clone cinder
echo "Cloning into cinder"

cd "c:\"
git clone $CinderRepoURL 

mkdir OpenStack
mkdir OpenStack\Log
mkdir iSCSIVirtualDisks

#Setup WinRM
echo "Setup WinRm"

$dest = "$env:temp\enable-winrm-https.ps1"
(New-Object System.Net.WebClient).DownloadFile($WinRMScriptURL, $dest)
& $dest

Get-WindowsFeature *Target-Server* | Add-WindowsFeature

# Setup SMB share
$share_path = "C:\share"
New-SmbShare -Name share -Path $share_path -FullAccess Everyone

# Grant full access to everyone.
$Acl = Get-ACL $share_path
$AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule(
    "everyone", "full", "ContainerInherit, Objectinherit", "none", "Allow")
$Acl.AddAccessRule($AccessRule)
Set-Acl $share_path $Acl
