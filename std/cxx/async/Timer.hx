package cxx.async;

#if cpp

import cxx.Function;

// Use the existing Promise from cxx._std
@:native("haxe::Promise")
extern class Promise<T> {}

/**
 * Timer class for async delays and scheduling
 */
@:headerInclude("<chrono>")
@:headerInclude("<thread>")
@:headerInclude("<functional>")
@:headerCode('
namespace haxe { namespace async {
    class Timer {
    public:
        static void delay(int milliseconds) {
            std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
        }
        
        static std::shared_ptr<haxe::Promise<void>> delayAsync(int milliseconds) {
            return std::make_shared<haxe::Promise<void>>(
                [milliseconds](auto resolve, auto reject) {
                    std::thread([milliseconds, resolve]() {
                        std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
                        resolve();
                    }).detach();
                }
            );
        }
        
        static void setTimeout(std::function<void()> callback, int milliseconds) {
            std::thread([callback, milliseconds]() {
                std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
                callback();
            }).detach();
        }
        
        static void setInterval(std::function<void()> callback, int milliseconds) {
            std::thread([callback, milliseconds]() {
                while (true) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
                    callback();
                }
            }).detach();
        }
    };
}}
')
@:native("haxe::async::Timer")
extern class Timer {
    /**
     * Synchronously delay execution for specified milliseconds
     */
    @:native("haxe::async::Timer::delay")
    public static function delay(milliseconds:Int):Void;
    
    /**
     * Asynchronously delay and return a Promise
     */
    @:native("haxe::async::Timer::delayAsync")
    public static function delayAsync(milliseconds:Int):Promise<Void>;
    
    /**
     * Execute a callback after specified milliseconds
     */
    @:native("haxe::async::Timer::setTimeout")
    public static function setTimeout(callback:()->Void, milliseconds:Int):Void;
    
    /**
     * Execute a callback repeatedly at specified intervals
     */
    @:native("haxe::async::Timer::setInterval")
    public static function setInterval(callback:()->Void, milliseconds:Int):Void;
}

#else

// Fallback implementation for non-C++ targets
class Timer {
    public static function delay(milliseconds:Int):Void {
        #if js
        // JavaScript doesn't have synchronous delay
        throw "Synchronous delay not supported in JavaScript";
        #else
        Sys.sleep(milliseconds / 1000.0);
        #end
    }
    
    public static function delayAsync(milliseconds:Int):Promise<Void> {
        return new Promise((resolve, reject) -> {
            #if js
            js.Browser.window.setTimeout(() -> resolve(), milliseconds);
            #else
            haxe.Timer.delay(() -> resolve(), milliseconds);
            #end
        });
    }
    
    public static function setTimeout(callback:()->Void, milliseconds:Int):Void {
        haxe.Timer.delay(callback, milliseconds);
    }
    
    public static function setInterval(callback:()->Void, milliseconds:Int):Void {
        var timer = new haxe.Timer(milliseconds);
        timer.run = callback;
    }
}

#end