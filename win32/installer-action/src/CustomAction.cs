using System;
using System.Collections.Generic;
using System.Text;
using System.IO;

using Microsoft.Deployment.WindowsInstaller;

using ICSharpCode.SharpZipLib.Zip;

namespace custom_action
{
    public class CustomActions
    {
        [CustomAction]
        public static ActionResult PreInstallAction(Session session)
        {
            session.Log("Begin PreInstallAction");

            try
            {
                var profileFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                var targetFolder = profileFolder + @"\Ultraschall\Backups\" + CreateTimestamp() + @"\REAPER";
                if (Directory.Exists(targetFolder) == false)
                {
                    Directory.CreateDirectory(targetFolder);
                }

                if (Directory.Exists(targetFolder) == true)
                {
                    var sourceFolder = profileFolder + @"\REAPER";
                    if (Directory.Exists(sourceFolder) == true)
                    {
                        CopyDirectory(sourceFolder, targetFolder);
                    }
                }

                session.Log("End PreInstallAction");
            }
            catch (Exception e)
            {
                session.Log(e.Message);
                session.Log(e.StackTrace);
            }

            return ActionResult.Success;
        }
        [CustomAction]
        public static ActionResult PostInstallAction(Session session)
        {
            session.Log("Begin PostInstallAction");

            try
            {
                var profileFolder = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                var sourceFile = profileFolder + @"\Ultraschall\Ultraschall_4.1.ReaperConfigZip";
                if (File.Exists(sourceFile) == true)
                {
                    var targetFolder = profileFolder + @"\REAPER";
                    if (Directory.Exists(targetFolder) == false)
                    {
                        Directory.CreateDirectory(targetFolder);
                    }

                    if (Directory.Exists(targetFolder) == true)
                    {
                        var zipEngine = new FastZip();
                        zipEngine.ExtractZip(sourceFile, targetFolder, FastZip.Overwrite.Always, null, null, null, false);
                    }
                }
            }
            catch (Exception e)
            {
                session.Log(e.Message);
                session.Log(e.StackTrace);
            }

            session.Log("End PostInstallAction");

            return ActionResult.Success;
        }

        private static string CreateTimestamp()
        {
            var timestamp = DateTime.Now.ToUniversalTime();
            var builder = new StringBuilder();
            builder.Append(timestamp.ToString("yyyyMMdd"));
            builder.Append("T");
            builder.Append(timestamp.ToString("Hmmss"));
            return builder.ToString();
        }

        private static void CopyDirectory(string source, string target)
        {
            var directoryInfo = new DirectoryInfo(source);
            if (directoryInfo.Exists == false)
            {
                throw new DirectoryNotFoundException(
                    "Source directory does not exist or could not be found: "
                    + source);
            }

            var directories = directoryInfo.GetDirectories();
            if (Directory.Exists(target) == false)
            {
                Directory.CreateDirectory(target);
            }

            var files = directoryInfo.GetFiles();
            foreach (var file in files)
            {
                var temppath = Path.Combine(target, file.Name);
                file.CopyTo(temppath, false);
            }

            // If copying subdirectories, copy them and their contents to new location.
            foreach (DirectoryInfo subDirectory in directories)
            {
                var newTarget = Path.Combine(target, subDirectory.Name);
                CopyDirectory(subDirectory.FullName, newTarget);
            }
        }
    }
}
