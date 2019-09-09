' -----------------------------------------------------------------------------------------
' sophos_update.vbs - plugin to monitor how many days passed since
' last update of Sophos Endpoint Security
'
' To use this just place it in the plugins/ directory below the path of the
' check_mk_agent. After that an inventory run on the Nagios host should lead
' to a new service.
'
' Author: Sebastian Kirchmeyer <kirchmeyer@pc.rwth-aachen.de>, 2018-01-04
' Editor: kener
'
' Based on code from Ronny Bruska.
'
' -----------------------------------------------------------------------------------------

Option Explicit

' Define Constants for the script exiting
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3
Const checkName = "Sophos_Last_Update"
Const output =  "Days since last update: "

' Define contants for WarnLevel und CritLevel for ease of changing
Const intWarnLevel = 1
Const intCritLevel = 3

function readFromRegistry (strRegistryKey, strDefault)
    Dim WSHShell, value

    On Error Resume Next
    Set WSHShell = CreateObject("WScript.Shell")
    value = WSHShell.RegRead( strRegistryKey )

    if err.number <> 0 then        
		WScript.echo intCritical & " " & "Sophos_Last_Update_Time - Registry Key not found"
		WScript.Quit(intCritLevel)
		readFromRegistry=strDefault
    else
        readFromRegistry=value
    end if

    set WSHShell = nothing
end function

Function regValueExists (key)
      'This function checks if a registry value exists and returns True of False
      On Error Resume Next
      Dim oShell
      Set oShell = CreateObject ("WScript.Shell")
      regValueExists = True
      Err.Clear
      oShell.RegRead(key)
      If Err <> 0 Then regValueExists = False
      Err.Clear
      Set oShell = Nothing
End Function

Dim RegPath, ObjShell, ObjProcess, strCPUArch
Set ObjShell = CreateObject("WScript.Shell")
Set ObjProcess = ObjShell.Environment("Process")

' Determine CPU architecture for correct location of the registry key
strCPUArch = ObjProcess("PROCESSOR_ARCHITECTURE")
If InStr(1, strCPUArch, "x86") > 0 Then
	RegPath ="HKLM\SOFTWARE\Sophos\AutoUpdate\UpdateStatus\"
ElseIf InStr(1, strCPUArch, "64") > 0 Then
	RegPath ="HKLM\SOFTWARE\WOW6432Node\Sophos\AutoUpdate\UpdateStatus\"
End If

Dim tZ, ShellObject, intDateDifference, lastUpdate, dateValue, status
tZ = +1
lastUpdate = readFromRegistry(RegPath & "LastUpdateTime", "Registry Key not found")
dateValue = DateAdd ("h",tZ,(DateAdd ("s",lastUpdate,"01/01/1970 00:00:00")))

If isDate(dateValue) = false then
	WScript.echo intUnknown & " " & checkName & " - " & "Not a valid date format: " & dateValue
	WScript.quit(intUnknown)
End If

intDateDifference = DateDiff("d", dateValue, Now)

If intDateDifference > intCritLevel then
	status = intCritical
ElseIf intDateDifference > intWarnLevel Then
	status = intWarning
ElseIf intDateDifference <= intWarnLevel Then
	status = intOK
End If

WScript.echo ("<<<sophos_update>>>" & vbLf & lastUpdate)
WScript.Quit()
