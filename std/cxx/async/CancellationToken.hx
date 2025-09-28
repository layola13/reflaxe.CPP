package cxx.async;

#if cpp

import cxx.Function;
import cxx.Ref;

/**
 * CancellationToken for cancelling async operations
 */
@:headerInclude("<atomic>")
@:headerInclude("<functional>")
@:headerInclude("<vector>")
@:headerInclude("<memory>")
@:headerCode('
namespace haxe { namespace async {
    class CancellationTokenSource;
    
    class CancellationToken {
    private:
        std::shared_ptr<std::atomic<bool>> cancelled;
        std::shared_ptr<std::vector<std::function<void()>>> callbacks;
        
    public:
        CancellationToken(std::shared_ptr<std::atomic<bool>> cancelFlag,
                         std::shared_ptr<std::vector<std::function<void()>>> callbackList)
            : cancelled(cancelFlag), callbacks(callbackList) {}
        
        bool isCancellationRequested() const {
            return cancelled && cancelled->load();
        }
        
        void throwIfCancellationRequested() const {
            if (isCancellationRequested()) {
                throw std::runtime_error("Operation cancelled");
            }
        }
        
        void register_callback(std::function<void()> callback) {
            if (isCancellationRequested()) {
                callback();
            } else if (callbacks) {
                callbacks->push_back(callback);
            }
        }
        
        friend class CancellationTokenSource;
    };
    
    class CancellationTokenSource {
    private:
        std::shared_ptr<std::atomic<bool>> cancelled;
        std::shared_ptr<std::vector<std::function<void()>>> callbacks;
        
    public:
        CancellationTokenSource() 
            : cancelled(std::make_shared<std::atomic<bool>>(false)),
              callbacks(std::make_shared<std::vector<std::function<void()>>>()) {}
        
        void cancel() {
            if (!cancelled->exchange(true)) {
                for (auto& callback : *callbacks) {
                    callback();
                }
                callbacks->clear();
            }
        }
        
        void reset() {
            cancelled->store(false);
            callbacks->clear();
        }
        
        CancellationToken token() {
            return CancellationToken(cancelled, callbacks);
        }
        
        bool isCancellationRequested() const {
            return cancelled->load();
        }
    };
}}
')
@:native("haxe::async::CancellationToken")
extern class CancellationToken {
    /**
     * Check if cancellation has been requested
     */
    @:native("isCancellationRequested")
    public function isCancellationRequested():Bool;
    
    /**
     * Throw an exception if cancellation has been requested
     */
    @:native("throwIfCancellationRequested")
    public function throwIfCancellationRequested():Void;
    
    /**
     * Register a callback to be called when cancellation is requested
     */
    @:native("register_callback")
    public function registerCallback(callback:()->Void):Void;
}

@:native("haxe::async::CancellationTokenSource")
extern class CancellationTokenSource {
    /**
     * Create a new CancellationTokenSource
     */
    @:native("new haxe::async::CancellationTokenSource")
    public function new();
    
    /**
     * Request cancellation
     */
    @:native("cancel")
    public function cancel():Void;
    
    /**
     * Reset the cancellation state
     */
    @:native("reset")
    public function reset():Void;
    
    /**
     * Get the cancellation token
     */
    @:native("token")
    public function getToken():CancellationToken;
    
    /**
     * Check if cancellation has been requested
     */
    @:native("isCancellationRequested")
    public function isCancellationRequested():Bool;
}

#else

// Fallback implementation for non-C++ targets
class CancellationToken {
    private var source:CancellationTokenSource;
    
    public function new(source:CancellationTokenSource) {
        this.source = source;
    }
    
    public function isCancellationRequested():Bool {
        return source.isCancellationRequested();
    }
    
    public function throwIfCancellationRequested():Void {
        if (isCancellationRequested()) {
            throw "Operation cancelled";
        }
    }
    
    public function registerCallback(callback:()->Void):Void {
        source.registerCallback(callback);
    }
}

class CancellationTokenSource {
    private var cancelled:Bool = false;
    private var callbacks:Array<()->Void> = [];
    
    public function new() {}
    
    public function cancel():Void {
        if (!cancelled) {
            cancelled = true;
            for (callback in callbacks) {
                callback();
            }
            callbacks = [];
        }
    }
    
    public function reset():Void {
        cancelled = false;
        callbacks = [];
    }
    
    public function getToken():CancellationToken {
        return new CancellationToken(this);
    }
    
    public function isCancellationRequested():Bool {
        return cancelled;
    }
    
    public function registerCallback(callback:()->Void):Void {
        if (cancelled) {
            callback();
        } else {
            callbacks.push(callback);
        }
    }
}

#end