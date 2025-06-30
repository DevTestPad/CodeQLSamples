using System;
using System.IO;
using System.Data.SqlClient;  // Back to the legacy namespace
using System.Net.Sockets;

namespace HelloWorld
{
    public class PoorResourceManagement
    {
        private FileStream? _logStream; // Field - won't be flagged when assigned to
        
        /// <summary>
        /// BAD: FileStream not disposed - will be flagged
        /// </summary>
        public void FileLeakExample()
        {
            var stream = new FileStream("temp.txt", FileMode.Create); // UNSAFE: Not disposed
            var buffer = new byte[1024];
            stream.Write(buffer, 0, buffer.Length);
            // stream is never disposed - resource leak!
        }
        
        /// <summary>
        /// BAD: Multiple resources not disposed - will be flagged
        /// </summary>
        public void DatabaseLeakExample()
        {
            var connection = new SqlConnection("Server=.;Database=Test;"); // UNSAFE: Not disposed  
            connection.Open();
            
            var command = new SqlCommand("SELECT 1", connection);          // UNSAFE: Not disposed
            var reader = command.ExecuteReader();                          // UNSAFE: Not disposed
            
            while (reader.Read())
            {
                Console.WriteLine(reader[0]);
            }
            // All resources leaked!
        }
        
        /// <summary>
        /// BAD: StreamWriter not disposed - will be flagged  
        /// </summary>
        public void WriterLeakExample()
        {
            var writer = new StreamWriter("output.txt");                   // UNSAFE: Not disposed
            writer.WriteLine("Hello World");
            writer.Flush();
            // writer never disposed - data may not be written to disk
        }
        
        /// <summary>
        /// BAD: Socket not disposed - will be flagged
        /// </summary>
        public void SocketLeakExample()
        {
            var socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp); // UNSAFE
            try
            {
                socket.Connect("127.0.0.1", 80);
                // Use socket...
            }
            catch
            {
                // Even if connection fails, socket should be disposed
            }
            // socket never closed or disposed
        }
        
        /// <summary>
        /// GOOD: Using statement ensures disposal - will NOT be flagged
        /// </summary>
        public void GoodFileUsage()
        {
            using var stream = new FileStream("temp.txt", FileMode.Create); // SAFE: using statement
            var buffer = new byte[1024];
            stream.Write(buffer, 0, buffer.Length);
        } // Automatically disposed here
        
        /// <summary>
        /// GOOD: Traditional using block - will NOT be flagged
        /// </summary>
        public void GoodFileUsageTraditional()
        {
            using (var stream = new FileStream("temp.txt", FileMode.Create)) // SAFE: using block
            {
                var buffer = new byte[1024];
                stream.Write(buffer, 0, buffer.Length);
            } // Automatically disposed here
        }
        
        /// <summary>
        /// GOOD: Explicit disposal - will NOT be flagged
        /// </summary>
        public void GoodExplicitDisposal()
        {
            var stream = new FileStream("temp.txt", FileMode.Create);
            try
            {
                var buffer = new byte[1024];
                stream.Write(buffer, 0, buffer.Length);
            }
            finally
            {
                stream.Dispose(); // SAFE: Explicit disposal
            }
        }
        
        /// <summary>
        /// GOOD: Close method called - will NOT be flagged
        /// </summary>
        public void GoodCloseMethod()
        {
            var socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            try
            {
                socket.Connect("127.0.0.1", 80);
                // Use socket...
            }
            finally
            {
                socket.Close(); // SAFE: Explicit close
            }
        }
        
        /// <summary>
        /// GOOD: Resource returned to caller - will NOT be flagged
        /// </summary>
        public FileStream OpenLogFile(string path)
        {
            var stream = new FileStream(path, FileMode.Append); // SAFE: Returned to caller
            return stream; // Caller is responsible for disposal
        }
        
        /// <summary>
        /// GOOD: Resource assigned to field - will NOT be flagged
        /// </summary>
        public void InitializeLogging(string path)
        {
            _logStream = new FileStream(path, FileMode.Append); // SAFE: Assigned to field
            // Typically disposed in class's Dispose method or finalizer
        }
        
        /// <summary>
        /// GOOD: Resource passed to method - will NOT be flagged
        /// </summary>
        public void ProcessFile(string path)
        {
            var stream = new FileStream(path, FileMode.Open); // SAFE: Passed to another method
            ProcessStream(stream); // Method may handle disposal
        }
        
        private void ProcessStream(FileStream stream)
        {
            // This method might dispose the stream, or wrap it in a using statement
            using (stream)
            {
                // Process stream...
                var buffer = new byte[1024];
                stream.Read(buffer, 0, buffer.Length);
            }
        }
        
        /// <summary>
        /// GOOD: Multiple resources with nested using - will NOT be flagged
        /// </summary>
        public void GoodNestedUsing()
        {
            using var connection = new SqlConnection("Server=.;Database=Test;"); // SAFE
            connection.Open();
            
            using var command = new SqlCommand("SELECT 1", connection);          // SAFE
            using var reader = command.ExecuteReader();                          // SAFE
            
            while (reader.Read())
            {
                Console.WriteLine(reader[0]);
            }
        } // All resources automatically disposed
        
        /// <summary>
        /// EDGE CASE: Null assignment - will NOT be flagged
        /// </summary>
        public void NullAssignment()
        {
            FileStream? stream = null; // SAFE: No resource to dispose
            // Demonstrate that the variable exists but has no resource to dispose
            Console.WriteLine($"Stream is null: {stream is null}");
        }
    }
}