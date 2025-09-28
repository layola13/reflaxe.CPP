package;

#if cpp

import cxx.Function;
import cxx.Ref;

/**
 * C++ implementation of Promise for async/await support
 */
@:headerInclude("<future>")
@:headerInclude("<thread>")
@:headerInclude("<functional>")
@:headerInclude("<vector>")
@:headerInclude("<memory>")
@:headerInclude("<exception>")
@:headerCode('
namespace haxe {
    template<typename T>
    class Promise {
    public:
        using ResolveFunc = std::function<void(T)>;
        using RejectFunc = std::function<void(std::exception_ptr)>;
        using ExecutorFunc = std::function<void(ResolveFunc, RejectFunc)>;
        
        enum class State {
            Pending,
            Fulfilled,
            Rejected
        };
        
    private:
        State state = State::Pending;
        T value;
        std::exception_ptr error;
        std::vector<std::function<void()>> callbacks;
        
    public:
        Promise(ExecutorFunc executor) {
            try {
                executor(
                    [this](T val) { resolve(val); },
                    [this](std::exception_ptr err) { reject(err); }
                );
            } catch(...) {
                reject(std::current_exception());
            }
        }
        
        void resolve(T val) {
            if (state != State::Pending) return;
            state = State::Fulfilled;
            value = val;
            executeCallbacks();
        }
        
        void reject(std::exception_ptr err) {
            if (state != State::Pending) return;
            state = State::Rejected;
            error = err;
            executeCallbacks();
        }
        
        template<typename TOut>
        std::shared_ptr<Promise<TOut>> then(std::function<TOut(T)> onFulfilled) {
            return std::make_shared<Promise<TOut>>(
                [this, onFulfilled](auto resolve, auto reject) {
                    addCallback([this, onFulfilled, resolve, reject]() {
                        if (state == State::Fulfilled) {
                            try {
                                resolve(onFulfilled(value));
                            } catch(...) {
                                reject(std::current_exception());
                            }
                        } else if (state == State::Rejected) {
                            reject(error);
                        }
                    });
                }
            );
        }
        
        std::shared_ptr<Promise<T>> catchError(std::function<T(std::exception_ptr)> onRejected) {
            return std::make_shared<Promise<T>>(
                [this, onRejected](auto resolve, auto reject) {
                    addCallback([this, onRejected, resolve, reject]() {
                        if (state == State::Fulfilled) {
                            resolve(value);
                        } else if (state == State::Rejected) {
                            try {
                                resolve(onRejected(error));
                            } catch(...) {
                                reject(std::current_exception());
                            }
                        }
                    });
                }
            );
        }
        
        static std::shared_ptr<Promise<T>> resolve(T value) {
            return std::make_shared<Promise<T>>(
                [value](auto resolve, auto reject) { resolve(value); }
            );
        }
        
        static std::shared_ptr<Promise<T>> reject(std::exception_ptr error) {
            return std::make_shared<Promise<T>>(
                [error](auto resolve, auto reject) { reject(error); }
            );
        }
        
        template<typename... Promises>
        static auto all(Promises... promises) {
            // Implementation for Promise.all
            // This would need more complex template metaprogramming
        }
        
    private:
        void addCallback(std::function<void()> callback) {
            if (state == State::Pending) {
                callbacks.push_back(callback);
            } else {
                callback();
            }
        }
        
        void executeCallbacks() {
            for (auto& callback : callbacks) {
                callback();
            }
            callbacks.clear();
        }
    };
}
')
@:native("haxe::Promise")
extern class Promise<T> {
    @:native("new haxe::Promise")
    function new(executor:(resolve:T->Void, reject:Dynamic->Void)->Void);
    
    function then<TOut>(onFulfilled:T->TOut):Promise<TOut>;
    
    @:native("catchError")
    function catchError(onRejected:Dynamic->T):Promise<T>;
    
    @:native("haxe::Promise<T>::resolve")
    static function resolve<T>(value:T):Promise<T>;
    
    @:native("haxe::Promise<T>::reject")
    static function reject<T>(error:Dynamic):Promise<T>;
    
    // Simplified versions for now
    static function all<T>(promises:Array<Promise<T>>):Promise<Array<T>>;
    static function race<T>(promises:Array<Promise<T>>):Promise<T>;
}

#else

// Fallback for non-C++ targets
@:jsRequire("promise")
extern class Promise<T> {
    function new(executor:(resolve:T->Void, reject:Dynamic->Void)->Void);
    function then<TOut>(onFulfilled:T->TOut):Promise<TOut>;
    @:native("catch") function catchError(onRejected:Dynamic->Dynamic):Promise<T>;
    static function resolve<T>(value:T):Promise<T>;
    static function reject<T>(reason:Dynamic):Promise<T>;
    static function all<T>(promises:Array<Promise<T>>):Promise<Array<T>>;
    static function race<T>(promises:Array<Promise<T>>):Promise<T>;
}

#end