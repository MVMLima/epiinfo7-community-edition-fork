using System;
using System.IO;
using System.Security;
using System.Security.Cryptography;

namespace Epi.Security
{
    /// <summary>
    /// Per-installation random key — replaces a key that used to be hardcoded in this file (a real problem now
    /// that the source is public). Old data falls back to the legacy keys below for compatibility.
    /// </summary>
    internal static class InstallationKeyProvider
    {
        private const string FolderName = "Epi Info 7";
        private const string KeyFileName = "security.key";

        private static readonly object syncLock = new object();
        private static bool loaded;
        private static string cachedPassPhrase;
        private static byte[] cachedSaltValueBytes;
        private static byte[] cachedInitVectorBytes;

        /// <summary>
        /// The per-installation passphrase, equivalent in usage to the legacy passPhrase constant.
        /// </summary>
        public static string PassPhrase
        {
            get
            {
                EnsureLoaded();
                return cachedPassPhrase;
            }
        }

        /// <summary>
        /// The per-installation salt bytes, equivalent in usage to the legacy saltValue constant.
        /// </summary>
        public static byte[] SaltValueBytes
        {
            get
            {
                EnsureLoaded();
                return cachedSaltValueBytes;
            }
        }

        /// <summary>
        /// The per-installation IV bytes, equivalent in usage to the legacy initVector constant.
        /// </summary>
        public static byte[] InitVectorBytes
        {
            get
            {
                EnsureLoaded();
                return cachedInitVectorBytes;
            }
        }

        private static void EnsureLoaded()
        {
            if (loaded)
            {
                return;
            }

            lock (syncLock)
            {
                if (loaded)
                {
                    return;
                }

                string keyFilePath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
                    FolderName,
                    KeyFileName);

                try
                {
                    LoadOrCreateKeyFile(keyFilePath);
                }
                catch (Exception ex)
                {
                    if (ex is UnauthorizedAccessException || ex is IOException || ex is SecurityException)
                    {
                        // Mirrors the ProgramData -> MyDocuments fallback used elsewhere in Configuration_Static.cs
                        // (see writableFilesFolder / baseFolder / DefaultConfigurationPath).
                        string fallbackFolder = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) + "\\" + FolderName + "\\";
                        string fallbackKeyFilePath = Path.Combine(fallbackFolder, KeyFileName);
                        LoadOrCreateKeyFile(fallbackKeyFilePath);
                    }
                    else
                    {
                        throw;
                    }
                }

                loaded = true;
            }
        }

        private static void LoadOrCreateKeyFile(string keyFilePath)
        {
            if (File.Exists(keyFilePath))
            {
                string[] lines = File.ReadAllLines(keyFilePath);
                cachedPassPhrase = lines[0];
                cachedSaltValueBytes = Convert.FromBase64String(lines[1]);
                cachedInitVectorBytes = Convert.FromBase64String(lines[2]);
                return;
            }

            string directory = Path.GetDirectoryName(keyFilePath);
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            byte[] passPhraseBytes = new byte[32];
            byte[] saltBytes = new byte[16];
            byte[] ivBytes = new byte[16];

            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(passPhraseBytes);
                rng.GetBytes(saltBytes);
                rng.GetBytes(ivBytes);
            }

            string passPhraseBase64 = Convert.ToBase64String(passPhraseBytes);
            string saltBase64 = Convert.ToBase64String(saltBytes);
            string ivBase64 = Convert.ToBase64String(ivBytes);

            File.WriteAllLines(keyFilePath, new[] { passPhraseBase64, saltBase64, ivBase64 });

            cachedPassPhrase = passPhraseBase64;
            cachedSaltValueBytes = saltBytes;
            cachedInitVectorBytes = ivBytes;
        }
    }
}
