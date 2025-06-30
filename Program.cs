// Simple Hello World console application with poor exception handling demo
using System;

namespace HelloWorld
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello, World!");
            Console.WriteLine("Welcome to .NET 8.0!");
            Console.WriteLine();

            // EXCEPTION HANDLING CHECKS
            // Demonstrate poor exception handling
            Console.WriteLine("=== Poor Exception Handling Demo ===");
            PoorExceptionHandler.TestBadExceptionHandling();

            Console.WriteLine();

            // Show what good exception handling looks like for comparison
            Console.WriteLine("=== Good Exception Handling Demo ===");
            try
            {
                PoorExceptionHandler.TestGoodExceptionHandling();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Handled at main level: {ex.Message}");
            }

            Console.WriteLine();


            // THREAT SAFE DICTIONARY CHECKS
            // Demonstrate unsafe dictionary usage
            Console.WriteLine("=== Dictionary Thread Safety Demo ===");
            var dictExample = new UnsafeDictionaryExamples();

            // This will trigger our CodeQL rule
            dictExample.UnsafeMultiThreadedAccess();

            // This shows the safe alternative
            dictExample.SafeLockedDictionaryAccess();
            dictExample.SafeConcurrentDictionaryUsage();

            Console.WriteLine();

            // Wait for user input before closing (optional)
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
            

            // MISSING DISPOSE OR CLOSE CHECKS
            Console.WriteLine("=== Resource Management Demo ===");
            var resourceExample = new PoorResourceManagement();
            
            Console.WriteLine("Demonstrating UNSAFE resource usage (will trigger CodeQL alerts):");
            try
            {
                resourceExample.FileLeakExample();           // Will be flagged by CodeQL
                Console.WriteLine("✗ File operation completed (but resource leaked!)");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"✗ File operation failed: {ex.Message}");
            }
            
            try
            {
                resourceExample.WriterLeakExample();         // Will be flagged by CodeQL  
                Console.WriteLine("✗ Write operation completed (but resource leaked!)");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"✗ Write operation failed: {ex.Message}");
            }
            
            Console.WriteLine("\nDemonstrating SAFE resource usage (will NOT trigger CodeQL alerts):");
            try
            {
                resourceExample.GoodFileUsage();             // Safe with using statement
                Console.WriteLine("✓ File operation completed safely with using statement");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"File operation failed: {ex.Message}");
            }
            
            try
            {
                resourceExample.GoodExplicitDisposal();      // Safe with explicit disposal
                Console.WriteLine("✓ File operation completed safely with explicit disposal");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"File operation failed: {ex.Message}");
            }
            
            // Demonstrate resource returned to caller (safe pattern)
            try
            {
                using var logStream = resourceExample.OpenLogFile("demo.log"); // Proper disposal
                Console.WriteLine("✓ Log file opened and will be disposed properly");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Log file operation failed: {ex.Message}");
            }
            
            Console.WriteLine();            
        }
    }
}