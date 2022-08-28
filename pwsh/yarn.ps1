# Do not use builtin $Args
Param
(
    [parameter(mandatory=$false, position=0, ValueFromRemainingArguments=$true)]$Argv
)

echo $PSScriptRoot
yarn @Argv
