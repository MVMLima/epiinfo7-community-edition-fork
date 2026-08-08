using System.Net;

namespace Epi.Security
{
    /// <summary>
    /// Ensures outbound HTTPS calls (REDCap sync, EpiWeb publish, MongoDB Atlas via AWSSDK, etc.) explicitly
    /// negotiate TLS 1.2, instead of silently relying on whatever the OS/.NET default happens to be — which is
    /// fragile on older Windows Server installs.
    /// </summary>
    public static class TlsConfiguration
    {
        static TlsConfiguration()
        {
            try
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            }
            catch
            {
                // Defensive only: should never actually trigger on .NET Framework 4.8, where Tls12 is always
                // supported. Swallow so a failure here can never crash app startup.
            }
        }

        /// <summary>
        /// Does nothing. Exists so callers can deliberately trigger the static constructor above by referencing
        /// this type — C# static constructors run on first type access, not eagerly.
        /// </summary>
        public static void Ensure()
        {
        }
    }
}
