using System;
using System.Collections.Generic;
using System.Text;
using System.IO;

using Microsoft.Deployment.WindowsInstaller;

namespace custom_action
{
  public class CustomActions
  {
    [CustomAction]
    public static ActionResult PreInstallAction(Session session) {
      session.Log("Begin PreInstallAction");
      try {
        var profileFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        var sourceFolder = profileFolder + @"\REAPER";
        // check for installed REAPER profile
        if (Directory.Exists(sourceFolder) == true) {
          var targetFolder = profileFolder + @"\Ultraschall\Backups\" + CreateTimestamp() + @"\REAPER";
          MoveDirectoryPreserveLicense(sourceFolder, targetFolder);
        }
        else {
          // nothing to do, bail out...
          session.Log("No backup required. Done.");
          return ActionResult.Success;
        }

        session.Log("End PreInstallAction");
      }
      catch (Exception e) {
        session.Log(e.Message);
        session.Log(e.StackTrace);
        return ActionResult.Failure;
      }
      return ActionResult.Success;
    }

    private static void MoveDirectoryPreserveLicense(String source, String target)
    {
      if (Directory.Exists(target) == false) {
        Directory.CreateDirectory(target);
      }

      var files = Directory.GetFiles(source);
      var directories = Directory.GetDirectories(source);
      foreach (var file in files) {
        File.Copy(file, Path.Combine(target, Path.GetFileName(file)));
        if (String.Equals(Path.GetFileName(file), "reaper-license.rk", StringComparison.OrdinalIgnoreCase) == false) {
          File.Delete(file);
        }
      }
      foreach (var directory in directories) {
        MoveDirectoryPreserveLicense(Path.Combine(source, Path.GetFileName(directory)), Path.Combine(target, Path.GetFileName(directory)));
        Directory.Delete(directory);
      }
    }

    private static string CreateTimestamp() {
      var timestamp = DateTime.Now.To
      var builder = new StringBuilder();
      builder.Append(timestamp.ToString("yyyyMMdd")).Append("T").Append(timestamp.ToString("Hmmss"));
      return builder.ToString();
    }
  }
}
