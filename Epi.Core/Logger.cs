using System;
using System.Collections.Generic;
using System.Text;
using System.IO;

using Epi.Data;
using Serilog;

namespace Epi
{
    /// <summary>
    /// Logs application events
    /// </summary>
    public static class Logger
    {
        #region Fields
        private static string logFilePath = string.Empty;

        /// <summary>
        /// Lazily-created, process-wide Serilog logger. Configured once, on first use, writing daily rolling
        /// plain-text files named "epiinfo-&lt;yyyyMMdd&gt;.txt" into the same LogDir the hand-rolled writer used
        /// to target, with a 14-day retention window.
        /// </summary>
        private static readonly Lazy<Serilog.Core.Logger> serilogLoggerLazy = new Lazy<Serilog.Core.Logger>(CreateSerilogLogger);
        #endregion Fields

        #region Public Methods

        /// <summary>
        ///  Logs an application message
        /// </summary>
        /// <param name="msg">Application message.</param>
        public static void Log(string msg)
        {
            try
            {
                serilogLoggerLazy.Value.Information(msg);
            }
            catch (Exception ex)
            {
                //absorb exception
            }
        }

        /// <summary>
        /// Formats a string and calls Log(...) if in DEBUG mode.
        /// </summary>
        /// <param name="description"></param>
        /// <param name="timeSpan"></param>
        public static void LogBenchmark(string description, TimeSpan timeSpan)
        {
#if (DEBUG)
            string msg = DateTime.Now.ToString() + " | " + description;
            Log(msg + " | " + timeSpan.ToString());
#endif
        }

        /// <summary>
        /// Logs a database query
        /// </summary>
        /// <param name="query"></param>
        public static void Log(Query query)
        {
            // Log the sql statement ...
            Log(query.SqlStatement);
            string paramsString = string.Empty;
            // Log parameters ...
            foreach (QueryParameter param in query.Parameters)
            {
                paramsString += param.ParameterName + "=" + (Util.IsEmpty(param.Value) ? String.Empty:param.Value.ToString()) + ";   ";
            }
            Log(paramsString);
        }

        /// <summary>
        /// Logs an application error, capturing the full exception (including stack trace).
        /// </summary>
        /// <param name="message">Description of what was happening when the error occurred.</param>
        /// <param name="ex">The exception that was encountered.</param>
        public static void LogError(string message, Exception ex)
        {
            try
            {
                serilogLoggerLazy.Value.Error(ex, message);
            }
            catch (Exception)
            {
                //absorb exception
            }
        }

        /// <summary>
        /// Returns the current log file path.
        /// </summary>
        /// <returns></returns>
        public static string GetLogFilePath()
        {
            EnsureLogFilePath();
            return logFilePath;
        }

        #endregion Public Methods

        #region Private Methods

        /// <summary>
        /// Creates the underlying Serilog logger, ensuring the log directory exists first — mirrors the
        /// directory-creation behavior of the old EnsureLogFileExists().
        /// </summary>
        private static Serilog.Core.Logger CreateSerilogLogger()
        {
            Configuration config = Configuration.GetNewInstance();

            if (!Directory.Exists(config.Directories.LogDir))
            {
                Directory.CreateDirectory(config.Directories.LogDir);
            }

            string logFileTemplate = Path.Combine(config.Directories.LogDir, "epiinfo-.txt");

            return new Serilog.LoggerConfiguration()
                .WriteTo.File(
                    logFileTemplate,
                    rollingInterval: Serilog.RollingInterval.Day,
                    retainedFileCountLimit: 14,
                    shared: true)
                .CreateLogger();
        }

        /// <summary>
        /// Computes the path of today's rolling log file, matching the "epiinfo-yyyyMMdd.txt" naming pattern
        /// that Serilog.Sinks.File produces for the "epiinfo-.txt" template with a Day rolling interval.
        /// </summary>
        private static bool EnsureLogFilePath()
        {
            try
            {
                Configuration config = Configuration.GetNewInstance();
                logFilePath = Path.Combine(config.Directories.LogDir, "epiinfo-" + DateTime.Now.ToString("yyyyMMdd") + ".txt");
                return true;
            }
            catch (Exception)
            {
                // Ignore any exceptions for now. TODO
                return false;
            }
        }
        #endregion Private Methods
    }
}
