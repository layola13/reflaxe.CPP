# reflaxe.CPP Async Programming Features

## Overview

reflaxe.CPP now includes comprehensive async/await support with a rich set of asynchronous programming utilities integrated directly into the standard library.

## Features

### 1. Promise Implementation (`cxx._std.Promise`)
Located in: `std/cxx/_std/Promise.hx`

- Full Promise/A+ specification implementation
- C++ backend using `std::future` and `std::thread`
- Methods: `then()`, `catchError()`, `resolve()`, `reject()`, `all()`, `race()`

### 2. Async Utilities (`cxx.async.*`)

#### Timer (`cxx.async.Timer`)
Located in: `std/cxx/async/Timer.hx`
- `delay(milliseconds)` - Synchronous delay
- `delayAsync(milliseconds)` - Returns a Promise
- `setTimeout(callback, milliseconds)` - Execute after delay
- `setInterval(callback, milliseconds)` - Execute repeatedly

#### CancellationToken (`cxx.async.CancellationToken`)
Located in: `std/cxx/async/CancellationToken.hx`
- Cancel async operations gracefully
- Register callbacks for cancellation events
- Thread-safe implementation using `std::atomic`

#### AsyncIterator (`cxx.async.AsyncIterator`)
Located in: `std/cxx/async/AsyncIterator.hx`
- Asynchronous iteration over data streams
- Methods: `map()`, `filter()`, `take()`, `reduce()`, `toArray()`
- Create from arrays with `AsyncIterator.from()`

#### Async Module (`cxx.async.Async`)
Located in: `std/cxx/async/Async.hx`
- Central module for all async utilities
- Helper functions: `delay()`, `parallel()`, `retry()`, `timeout()`, `promisify()`

### 3. Compiler Support

#### @:async Metadata
The compiler (in `src/cxxcompiler/subcompilers/Expressions.hx`) recognizes `@:async` metadata on functions:

```haxe
@:async
function fetchData():Promise<String> {
    return Promise.resolve("data");
}
```

#### @:await Metadata (Future Enhancement)
Placeholder for future `@:await` expression support:

```haxe
@:async
function example():Promise<Void> {
    var result = @:await fetchData();
    trace(result);
}
```

## Usage Examples

### Basic Promise Usage
```haxe
import cxx._std.Promise;

class Example {
    static function main() {
        var promise = Promise.resolve(42);
        promise.then(value -> {
            trace("Value: " + value);
            return value * 2;
        }).then(doubled -> {
            trace("Doubled: " + doubled);
        });
    }
}
```

### Using Async Utilities
```haxe
import cxx.async.Async;
import cxx.async.Timer;
import cxx.async.CancellationTokenSource;
import cxx.async.AsyncIterator;

class AsyncExample {
    static function main() {
        // Delay execution
        Timer.delayAsync(1000).then(_ -> {
            trace("1 second passed");
        });
        
        // Cancellable operation
        var cts = new CancellationTokenSource();
        var token = cts.getToken();
        
        performOperation(token).catchError(error -> {
            trace("Operation cancelled: " + error);
        });
        
        // Cancel after 5 seconds
        Timer.setTimeout(() -> cts.cancel(), 5000);
        
        // Async iteration
        var numbers = AsyncIterator.from([1, 2, 3, 4, 5]);
        numbers
            .map(x -> x * 2)
            .filter(x -> x > 5)
            .toArray()
            .then(result -> trace(result)); // [6, 8, 10]
    }
    
    static function performOperation(token:CancellationToken):Promise<String> {
        return new Promise((resolve, reject) -> {
            token.registerCallback(() -> reject("Cancelled"));
            
            Timer.setTimeout(() -> {
                if (!token.isCancellationRequested()) {
                    resolve("Operation completed");
                }
            }, 10000);
        });
    }
}
```

### Advanced Patterns
```haxe
import cxx.async.Async;

class AdvancedAsync {
    static function main() {
        // Parallel execution with concurrency limit
        var tasks = [
            () -> fetchData("url1"),
            () -> fetchData("url2"),
            () -> fetchData("url3"),
            () -> fetchData("url4"),
            () -> fetchData("url5")
        ];
        
        Async.parallel(tasks, 2).then(results -> {
            trace("All results: " + results);
        });
        
        // Retry with exponential backoff
        Async.retry(
            () -> unreliableOperation(),
            3,      // max attempts
            1000,   // initial delay
            2.0     // backoff multiplier
        ).then(result -> {
            trace("Success: " + result);
        });
        
        // Timeout handling
        var slowOperation = Timer.delayAsync(10000).then(_ -> "Done");
        
        Async.timeout(slowOperation, 5000, "Too slow!")
            .then(result -> trace(result))
            .catchError(error -> trace("Timeout: " + error));
    }
    
    static function fetchData(url:String):Promise<String> {
        return Timer.delayAsync(1000).then(_ -> "Data from " + url);
    }
    
    static function unreliableOperation():Promise<String> {
        if (Math.random() > 0.7) {
            return Promise.resolve("Success");
        }
        return Promise.reject("Random failure");
    }
}
```

## File Structure

```
reflaxe.CPP/
├── std/
│   ├── cxx/
│   │   ├── _std/
│   │   │   └── Promise.hx          # Core Promise implementation
│   │   └── async/
│   │       ├── Async.hx            # Main async module
│   │       ├── Timer.hx            # Timer utilities
│   │       ├── CancellationToken.hx # Cancellation support
│   │       └── AsyncIterator.hx    # Async iteration
│   └── ...
└── src/
    └── cxxcompiler/
        └── subcompilers/
            └── Expressions.hx       # @:async/@:await support
```

## Building Projects

When using async features, ensure your build configuration includes:

```hxml
# Use reflaxe.CPP library
--library reflaxe.CPP

# C++20 for better async support
-D cxx-std=c++20

# Include async features
--class-path std
```

## C++ Output

The async utilities generate modern C++ code using:
- `std::promise` and `std::future` for async operations
- `std::thread` for concurrent execution
- `std::atomic` for thread-safe state management
- `std::chrono` for timing operations
- `std::function` for callbacks

## Future Enhancements

1. **C++20 Coroutines**: Integration with `co_await`, `co_return`, `co_yield`
2. **Full @:await Support**: Transform await expressions into continuation-passing style
3. **Async Generators**: Support for `async function*` and `yield`
4. **Structured Concurrency**: Task groups and cancellation scopes
5. **Async Streams**: Reactive programming with observables

## Contributing

To extend async support:
1. Add new utilities in `std/cxx/async/`
2. Update compiler support in `src/cxxcompiler/subcompilers/Expressions.hx`
3. Add tests in the test suite
4. Update this documentation

## License

Part of the reflaxe.CPP project - see main LICENSE file.