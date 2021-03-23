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
                //var targetFolder = profileFolder + @"\Ultraschall\Backups\" + CreateTimestamp() + @"\REAPER";
                var targetFolder = profileFolder + @"\Ultraschall\Backups\" + CreateTimestamp();
                var sourceFolder = profileFolder + @"\REAPER";

                // check for installed REAPER profile
                if (Directory.Exists(sourceFolder) == false) 
                {
                    // nothing to do, bail out...
                    session.Log("No backup required. Done.");
                    return ActionResult.Success;
                }

                // move REAPER profile to backup folder
                session.Log("Creating target folder: " + targetFolder);
                if (Directory.Exists(targetFolder) == false)
                {
                  Directory.CreateDirectory(targetFolder);
                }

                session.Log("Moving " + sourceFolder + " to " + targetFolder);
                if (Directory.Exists(targetFolder) == true)
                {
                  targetFolder += @"\REAPER";
                  Directory.Move(sourceFolder, targetFolder);
                }

          // Restore license file
         String sourceLicense = targetFolder + @"\reaper-license.rk";
        if (File.Exists(sourceLicense))
        {
          session.Log("Restoring license file");
          if (Directory.Exists(sourceFolder) == false)
          {
            Directory.CreateDirectory(sourceFolder);
          }

          if (Directory.Exists(sourceFolder))
          {
            String targetLicense = sourceFolder + @"\reaper-license.rk";
            File.Copy(sourceLicense, targetLicense);
          }
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
    //[CustomAction]
    //public static ActionResult PreInstallAction(Session session)
    //{
    //  session.Log("Begin PreInstallAction");

    //  try
    //  {
    //    var profileFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
    //    var targetFolder = profileFolder + @"\Ultraschall\Backups\" + CreateTimestamp() + @"\REAPER";
    //    var sourceFolder = profileFolder + @"\REAPER";
    //    var outdatedFolder = profileFolder + @"\REAPER_OUTDATED";

    //    // check for installed REAPER profile
    //    if (Directory.Exists(sourceFolder) == false)
    //    {
    //      // nothing to do, bail out...
    //      session.Log("No backup required. Done.");
    //      return ActionResult.Success;
    //    }

    //    // Remove potential left-overs from previous run
    //    if (Directory.Exists(outdatedFolder))
    //    {
    //      session.Log("Cleaning up files from previous installation");
    //      Directory.Delete(outdatedFolder, true);
    //    }

    //    // create backup folder
    //    if (Directory.Exists(targetFolder) == false)
    //    {
    //      session.Log("Creating backup folder");
    //      Directory.CreateDirectory(targetFolder);
    //    }

    //    // Backup
    //    if (Directory.Exists(targetFolder) == true)
    //    {
    //      session.Log("Copying files to backup folder");
    //      // Backup installed profile
    //      if (CopyDirectory(sourceFolder, targetFolder) == false)
    //      {
    //        session.Log("ERROR: Failed to copy files to backup folder");
    //        return ActionResult.Failure;
    //      }
    //    }

    //    // Move installed profile out of the way
    //    session.Log("Creating outdated folder");
    //    Directory.Move(sourceFolder, outdatedFolder);

    //    // Restore license file
    //    String sourceLicense = targetFolder + @"\reaper-license.rk";
    //    if (File.Exists(sourceLicense))
    //    {
    //      session.Log("Restoring license file");
    //      if (Directory.Exists(sourceFolder) == false)
    //      {
    //        Directory.CreateDirectory(sourceFolder);
    //      }

    //      if (Directory.Exists(sourceFolder))
    //      {
    //        String targetLicense = sourceFolder + @"\reaper-license.rk";
    //        File.Copy(sourceLicense, targetLicense);
    //      }
    //    }

    //    // Remove previously installed profile
    //    if (Directory.Exists(outdatedFolder))
    //    {
    //      session.Log("Removing outdated folder");
    //      Directory.Delete(outdatedFolder, true);
    //    }

    //    session.Log("End PreInstallAction");
    //  }
    //  catch (Exception e)
    //  {
    //    session.Log(e.Message);
    //    session.Log(e.StackTrace);
    //    return ActionResult.Failure;
    //  }

    //  return ActionResult.Success;
    //}
    //[CustomAction]
    //public static ActionResult PostInstallAction(Session session)
    //{
    //    session.Log("Begin PostInstallAction");

    //    try
    //    {
    //        var profileFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
    //        var sourceFile = profileFolder + @"\Ultraschall\Ultraschall_4.1.ReaperConfigZip";
    //        if (File.Exists(sourceFile) == true)
    //        {
    //            var targetFolder = profileFolder + @"\REAPER";
    //            if (Directory.Exists(targetFolder) == false)
    //            {
    //                Directory.CreateDirectory(targetFolder);
    //            }

    //            if (Directory.Exists(targetFolder) == true)
    //            {
    //                var zipEngine = new FastZip();
    //                zipEngine.ExtractZip(sourceFile, targetFolder, FastZip.Overwrite.Always, null, null, null, false);
    //            }
    //        }
    //    }
    //    catch (Exception e)
    //    {
    //        session.Log(e.Message);
    //        session.Log(e.StackTrace);
    //    }

    //    session.Log("End PostInstallAction");

    //    return ActionResult.Success;
    //}

    private static string CreateTimestamp() {
            var timestamp = DateTime.Now.ToUniversalTime();
            var builder = new StringBuilder();
            builder.Append(timestamp.ToString("yyyyMMdd"));
            builder.Append("T");
            builder.Append(timestamp.ToString("Hmmss"));
            return builder.ToString();
        }

        private static bool CopyDirectory(string source, string target) {
            var directoryInfo = new DirectoryInfo(source);
            if (directoryInfo.Exists == false) {
                return false;
            }

            var directories = directoryInfo.GetDirectories();
            if (Directory.Exists(target) == false) {
                Directory.CreateDirectory(target);
            }

            var files = directoryInfo.GetFiles();
            foreach (var file in files) {
                var temppath = Path.Combine(target, file.Name);
                file.CopyTo(temppath, false);
            }

            // If copying subdirectories, copy them and their contents to new location.
            foreach (DirectoryInfo subDirectory in directories) {
                var newTarget = Path.Combine(target, subDirectory.Name);
                if (CopyDirectory(subDirectory.FullName, newTarget) == false) {
                    return false;
                }
            }

            return true;
        }
    }
}
