<#PSScriptInfo
.VERSION 0.5

.AUTHOR elderica

.LICENSEURI https://opensource.org/license/mit
#>

<#
.DESCRIPTION
 これは、Windowsマシンにchatux-server-llm(https://github.com/sotokisehiro/chatux-server-llm)をインストールするPowerShellスクリプトです。
 PowerShell 7.4.1で動作確認しています。

 このスクリプトを使う前にビルドツールとして、Git、Visual Studio BuildTools 2022、CMakeをインストールしてください。
 BuildToolsの代わりにVisual Studio 2022を使うこともできます。
 例えばwingetを使って次のようにインストールします。
 > winget install Git.Git Microsoft.VisualStudio.2022.BuildTools Kitware.CMake
 wingetを使ってビルドツールをインストールしたら、PowerShellを再起動してください。
 このスクリプトを次のように起動することで、chatux-server-llmをインストールできます。
 > . ./Install-Chatux.ps1

 chatux-server-llmをインストールできたら、次の操作をすれば動かせます。
 変数は実際のパス文字列に置き換えてください。
 > cd $chatux_prefix
 > & $python main.py
#>

Start-Transcript
Set-StrictMode -Version 3.0 -Verbose
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$prefix = "C:\opt\chatux"

$python_version = "3.12.2"
$python_prefix = "$prefix/python"
$python = "$python_prefix/python.exe"
$python_embedded_package = "$prefix/python-$python_version-embed-amd64.zip"
$python_embedded_package_uri = "https://www.python.org/ftp/python/$python_version/python-$python_version-embed-amd64.zip"

$getpip = "$prefix/get-pip.py"
$getpip_uri = "https://bootstrap.pypa.io/get-pip.py"

$chatux_prefix = "$prefix/chatux-server-llm"
$chatux_git_uri = "https://github.com/sotokisehiro/chatux-server-llm.git"

$model_uri = "https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-7b-fast-instruct-gguf/resolve/main/ELYZA-japanese-Llama-2-7b-fast-instruct-q4_K_M.gguf"
$model_path = "$chatux_prefix/models/ELYZA-japanese-Llama-2-7b-fast-instruct-q4_K_M.gguf"

# インストール先のディレクトリを準備する
if (!(Test-Path -PathType Container -Path $prefix)) {
    New-Item -ItemType Directory -Force -Path $prefix
}

# Python(Windows embeddable package)をダウンロードする
if (!(Test-Path -PathType Leaf -Path $python_embedded_package)) {
    Invoke-WebRequest -OutFile $python_embedded_package -Uri $python_embedded_package_uri
}
if (!(Test-Path -PathType Container -Path $python_prefix)) {
    Expand-Archive -Force -DestinationPath $python_prefix -Path $python_embedded_package
    Add-Content -Path "$python_prefix/*._pth" -Value "import site"
    # chatux-server-llmのあるディレクトリからモジュールをロードできるようにする
    Add-Content -Path "$python_prefix/*._pth" -Value $chatux_prefix
}

# pipが使えるようにする
if (!(Test-Path -PathType Leaf -Path $getpip)) {
    Invoke-WebRequest -OutFile $getpip -Uri $getpip_uri
}
& $python $getpip

# chatux-server-llmをダウンロードする
if (!(Test-Path -PathType Container -Path $chatux_prefix)) {
    git clone $chatux_git_uri $chatux_prefix
}

# chatux-server-llmの依存関係をインストールする
& $python -m pip install scikit-build-core pyproject-metadata pathspec
& $python -m pip install -r "$chatux_prefix/requirements.txt"

# モデルファイルをダウンロードする
# Copy-Item -Path "C:\opt\ELYZA-japanese-Llama-2-7b-fast-instruct-q4_K_M.gguf" -Destination $model_path
if (!(Test-Path -PathType Leaf -Path $model_path)) {
    Invoke-WebRequest -OutFile $model_path -Uri $model_uri
}

$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
Set-StrictMode -Off
Stop-Transcript
