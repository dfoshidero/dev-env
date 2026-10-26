# Check that a font family resolves through DirectWrite, the font stack Windows
# Terminal, VS Code and Cursor render with. Read-only; exits 1 if the family is missing.
param(
    [string]$FamilyName = "JetBrainsMono Nerd Font"
)

$ErrorActionPreference = "Stop"

if (-not ("DevEnvDirectWrite" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class DevEnvDirectWrite {
  [DllImport("dwrite.dll")]
  static extern int DWriteCreateFactory(int factoryType, ref Guid iid, out IntPtr factory);

  [UnmanagedFunctionPointer(CallingConvention.StdCall)]
  delegate int GetSystemFontCollection(IntPtr self, out IntPtr collection, bool checkForUpdates);

  [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet = CharSet.Unicode)]
  delegate int FindFamilyName(IntPtr self, string familyName, out uint index, out bool exists);

  // COM vtable slot i of obj (0-2 are IUnknown).
  static IntPtr Slot(IntPtr obj, int i) {
    return Marshal.ReadIntPtr(Marshal.ReadIntPtr(obj), i * IntPtr.Size);
  }

  public static bool FamilyExists(string familyName) {
    Guid iidFactory = new Guid("b859ee5a-d838-4b5b-a2e8-1adc7d93db48");
    IntPtr factory, collection;
    uint index;
    bool exists;
    Marshal.ThrowExceptionForHR(DWriteCreateFactory(0, ref iidFactory, out factory));
    try {
      var getCollection = (GetSystemFontCollection)Marshal.GetDelegateForFunctionPointer(
        Slot(factory, 3), typeof(GetSystemFontCollection));
      Marshal.ThrowExceptionForHR(getCollection(factory, out collection, true));
      try {
        var find = (FindFamilyName)Marshal.GetDelegateForFunctionPointer(
          Slot(collection, 5), typeof(FindFamilyName));
        Marshal.ThrowExceptionForHR(find(collection, familyName, out index, out exists));
        return exists;
      } finally {
        Marshal.Release(collection);
      }
    } finally {
      Marshal.Release(factory);
    }
  }
}
"@
}

if ([DevEnvDirectWrite]::FamilyExists($FamilyName)) {
    Write-Output "Windows can render '$FamilyName'"
    exit 0
}

Write-Output "Windows cannot find the font family '$FamilyName'"
exit 1
