using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;

namespace HelloWorld
{
    public class UnsafeDictionaryExamples
    {
        // Static dictionary shared across threads - potential issue
        private static Dictionary<string, int> _sharedCache = new Dictionary<string, int>();
        private static readonly object _lockObject = new object();
        
        // Instance dictionary that might be accessed from multiple threads
        private Dictionary<int, string> _instanceDict = new Dictionary<int, string>();

        /// <summary>
        /// BAD: Unsafe dictionary access in multi-threaded scenario
        /// </summary>
        public void UnsafeMultiThreadedAccess()
        {
            // BAD: Multiple tasks accessing shared dictionary without locking
            Task.Run(() =>
            {
                _sharedCache.Add("key1", 1); // UNSAFE: No locking
                _sharedCache["key2"] = 2;    // UNSAFE: No locking
            });

            Task.Run(() =>
            {
                if (_sharedCache.ContainsKey("key1")) // UNSAFE: No locking
                {
                    var value = _sharedCache["key1"]; // UNSAFE: No locking
                }
                _sharedCache.Remove("key2"); // UNSAFE: No locking
            });
        }

        /// <summary>
        /// BAD: Threading method with unsafe dictionary operations
        /// </summary>
        public async Task UnsafeAsyncDictionaryAccess()
        {
            await Task.Run(() =>
            {
                // BAD: Dictionary operations without locking in async context
                _instanceDict.Add(1, "value1");
                _instanceDict[2] = "value2";
                
                if (_instanceDict.TryGetValue(1, out string result))
                {
                    Console.WriteLine(result);
                }
            });
        }

        /// <summary>
        /// GOOD: Safe dictionary access with proper locking
        /// </summary>
        public void SafeLockedDictionaryAccess()
        {
            Task.Run(() =>
            {
                lock (_lockObject)
                {
                    _sharedCache.Add("safe_key1", 1); // SAFE: Within lock
                    _sharedCache["safe_key2"] = 2;    // SAFE: Within lock
                }
            });

            Task.Run(() =>
            {
                lock (_lockObject)
                {
                    if (_sharedCache.ContainsKey("safe_key1")) // SAFE: Within lock
                    {
                        var value = _sharedCache["safe_key1"]; // SAFE: Within lock
                    }
                    _sharedCache.Remove("safe_key2"); // SAFE: Within lock
                }
            });
        }

        /// <summary>
        /// GOOD: Using ConcurrentDictionary for thread-safe operations
        /// </summary>
        public void SafeConcurrentDictionaryUsage()
        {
            var concurrentDict = new ConcurrentDictionary<string, int>();

            Task.Run(() =>
            {
                concurrentDict.TryAdd("key1", 1);    // SAFE: ConcurrentDictionary
                concurrentDict["key2"] = 2;          // SAFE: ConcurrentDictionary
            });

            Task.Run(() =>
            {
                if (concurrentDict.ContainsKey("key1")) // SAFE: ConcurrentDictionary
                {
                    concurrentDict.TryGetValue("key1", out int value);
                }
                concurrentDict.TryRemove("key2", out _); // SAFE: ConcurrentDictionary
            });
        }

        /// <summary>
        /// GOOD: Single-threaded dictionary usage (no threading indicators)
        /// </summary>
        public void SafeSingleThreadedUsage()
        {
            var localDict = new Dictionary<string, int>();
            
            // SAFE: No multi-threading context
            localDict.Add("key1", 1);
            localDict["key2"] = 2;
            
            if (localDict.ContainsKey("key1"))
            {
                var value = localDict["key1"];
            }
        }
    }
}