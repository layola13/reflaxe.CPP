package cxx.async;

/**
 * Main async module that exports all async utilities
 */

#if cpp

// Re-export all async utilities
typedef Promise<T> = cxx._std.Promise<T>;
typedef Timer = cxx.async.Timer;
typedef CancellationToken = cxx.async.CancellationToken;
typedef CancellationTokenSource = cxx.async.CancellationTokenSource;
typedef AsyncIterator<T> = cxx.async.AsyncIterator<T>;

#else

// Fallback for non-C++ targets
#if js
typedef Promise<T> = js.lib.Promise<T>;
#else
// For other targets, use a simple Promise implementation
class Promise<T> {
    public function new(executor:(resolve:T->Void, reject:Dynamic->Void)->Void) {}
    public function then<U>(onFulfilled:T->U):Promise<U> { return cast this; }
    public function catchError(onRejected:Dynamic->Dynamic):Promise<T> { return this; }
    public static function resolve<T>(value:T):Promise<T> { return new Promise((r,_) -> r(value)); }
    public static function reject<T>(reason:Dynamic):Promise<T> { return new Promise((_,r) -> r(reason)); }
    public static function all<T>(promises:Array<Promise<T>>):Promise<Array<T>> { return cast promises[0]; }
    public static function race<T>(promises:Array<Promise<T>>):Promise<T> { return promises[0]; }
}
#end

#end

/**
 * Async utilities for reflaxe.CPP
 * 
 * Usage:
 * ```haxe
 * import cxx.async.Async;
 * 
 * class Example {
 *     @:async
 *     static function fetchData():Promise<String> {
 *         return Promise.resolve("data");
 *     }
 *     
 *     static function main() {
 *         var promise = fetchData();
 *         promise.then(data -> trace(data));
 *         
 *         // Use Timer for delays
 *         Timer.delayAsync(1000).then(_ -> trace("1 second passed"));
 *         
 *         // Use CancellationToken for cancellable operations
 *         var cts = new CancellationTokenSource();
 *         var token = cts.getToken();
 *         
 *         // Use AsyncIterator for streaming data
 *         var iter = AsyncIterator.from([1, 2, 3, 4, 5]);
 *         iter.map(x -> x * 2)
 *             .filter(x -> x > 4)
 *             .toArray()
 *             .then(arr -> trace(arr)); // [6, 8, 10]
 *     }
 * }
 * ```
 */
class Async {
    /**
     * Create a Promise that resolves after a delay
     */
    public static inline function delay(milliseconds:Int):Promise<Void> {
        #if cpp
        return Timer.delayAsync(milliseconds);
        #else
        return new Promise((resolve, reject) -> {
            haxe.Timer.delay(() -> resolve(), milliseconds);
        });
        #end
    }
    
    /**
     * Run multiple Promises in parallel with a concurrency limit
     */
    public static function parallel<T>(
        tasks:Array<()->Promise<T>>, 
        concurrency:Int = 5
    ):Promise<Array<T>> {
        var results:Array<T> = [];
        var index = 0;
        
        function runNext():Promise<Void> {
            if (index >= tasks.length) {
                return Promise.resolve();
            }
            
            var currentIndex = index++;
            return tasks[currentIndex]().then(result -> {
                results[currentIndex] = result;
                return runNext();
            });
        }
        
        var runners:Array<Promise<Void>> = [];
        for (i in 0...Math.min(concurrency, tasks.length)) {
            runners.push(runNext());
        }
        
        #if cpp
        return Promise.all(runners).then(_ -> results);
        #else
        return Promise.all(runners).then(_ -> results);
        #end
    }
    
    /**
     * Retry an async operation with exponential backoff
     */
    public static function retry<T>(
        operation:()->Promise<T>,
        maxAttempts:Int = 3,
        delayMs:Int = 1000,
        backoffMultiplier:Float = 2.0
    ):Promise<T> {
        function attempt(attemptNum:Int, currentDelay:Int):Promise<T> {
            return operation().catchError((error:Dynamic) -> {
                if (attemptNum >= maxAttempts) {
                    return Promise.reject(error);
                }
                
                return delay(currentDelay).then(_ -> {
                    return attempt(
                        attemptNum + 1,
                        Math.round(currentDelay * backoffMultiplier)
                    );
                });
            });
        }
        
        return attempt(1, delayMs);
    }
    
    /**
     * Create a Promise that times out after a specified duration
     */
    public static function timeout<T>(
        promise:Promise<T>,
        milliseconds:Int,
        timeoutMessage:String = "Operation timed out"
    ):Promise<T> {
        var timeoutPromise = delay(milliseconds).then(_ -> {
            throw timeoutMessage;
        });
        
        #if cpp
        return Promise.race([promise, timeoutPromise]);
        #else
        return Promise.race([promise, timeoutPromise]);
        #end
    }
    
    /**
     * Convert a callback-based function to a Promise
     */
    public static function promisify<T>(
        operation:(callback:(error:Dynamic, result:T)->Void)->Void
    ):Promise<T> {
        return new Promise((resolve, reject) -> {
            operation((error, result) -> {
                if (error != null) {
                    reject(error);
                } else {
                    resolve(result);
                }
            });
        });
    }
    
    /**
     * Execute an async operation and ignore any errors
     */
    public static function ignoreErrors<T>(promise:Promise<T>):Promise<Null<T>> {
        return promise
            .then(value -> (value : Null<T>))
            .catchError(_ -> Promise.resolve(null));
    }
}