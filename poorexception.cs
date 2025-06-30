using System;

namespace HelloWorld
{
    public class PoorExceptionHandler
    {
        /// <summary>
        /// This method demonstrates poor exception handling practices.
        /// It throws a first chance exception that gets caught and hidden.
        /// </summary>
        public static void TestBadExceptionHandling()
        {
            Console.WriteLine("Testing poor exception handling...");
            
            try
            {
                // This will throw a first chance exception
                DangerousOperation();
            }
            catch (Exception)
            {
                // BAD PRACTICE: Generic exception handler that hides the error
                // This swallows all exceptions without logging, rethrowing, or handling properly
                // The exception is completely hidden from the caller
            }
            
            Console.WriteLine("Operation completed (but we don't know if it actually succeeded!)");
        }
        
        /// <summary>
        /// Simulates a dangerous operation that can fail in multiple ways
        /// </summary>
        private static void DangerousOperation()
        {
            Console.WriteLine("Performing dangerous operation...");
            
            // Simulate different types of exceptions that could occur
            Random random = new Random();
            int errorType = random.Next(1, 4);
            
            switch (errorType)
            {
                case 1:
                    throw new InvalidOperationException("Database connection failed");
                case 2:
                    throw new ArgumentNullException("Required parameter is null");
                case 3:
                    throw new UnauthorizedAccessException("Access denied to resource");
                default:
                    throw new Exception("Unknown error occurred");
            }
        }
        
        /// <summary>
        /// Alternative method showing what GOOD exception handling might look like
        /// (for comparison purposes)
        /// </summary>
        public static void TestGoodExceptionHandling()
        {
            Console.WriteLine("\nTesting GOOD exception handling for comparison...");
            
            try
            {
                DangerousOperation();
            }
            catch (InvalidOperationException ex)
            {
                Console.WriteLine($"Database error: {ex.Message}");
                // Could implement retry logic here
            }
            catch (ArgumentNullException ex)
            {
                Console.WriteLine($"Parameter error: {ex.Message}");
                // Could validate inputs and provide defaults
            }
            catch (UnauthorizedAccessException ex)
            {
                Console.WriteLine($"Security error: {ex.Message}");
                // Could redirect to login or request permissions
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Unexpected error: {ex.Message}");
                // Log the error and potentially rethrow
                throw; // Rethrow to let caller handle it
            }
        }
    }
}
