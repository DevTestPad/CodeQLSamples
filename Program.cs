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
            
            // Demonstrate poor exception handling
            Console.WriteLine("=== Poor Exception Handling Demo ===");
            PoorExceptionHandler.TestBadExceptionHandling();
            
            Console.WriteLine();
            
            // Demonstrate unsafe dictionary usage
            Console.WriteLine("=== Dictionary Thread Safety Demo ===");
            var dictExample = new UnsafeDictionaryExamples();
            
            // This will trigger our CodeQL rule
            dictExample.UnsafeMultiThreadedAccess();
            
            // This shows the safe alternative
            dictExample.SafeLockedDictionaryAccess();
            dictExample.SafeConcurrentDictionaryUsage();
            
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
            
            // Wait for user input before closing (optional)
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }
}