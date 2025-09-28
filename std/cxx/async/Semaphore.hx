package cxx.async;

#if cpp

/**
 * Semaphore - Limit concurrent access to resources
 */
@:headerInclude("<atomic>")
@:headerInclude("<queue>")
@:headerInclude("<mutex>")
@:headerInclude("<condition_variable>")
@:headerCode('
namespace haxe { namespace async {
    class Semaphore {
    private:
        std::atomic<int> permits;
        int maxPermits;
        std::queue<std::function<void()>> waitQueue;
        std::mutex mutex;
        std::condition_variable cv;
        
    public:
        Semaphore(int initialPermits) 
            : permits(initialPermits), maxPermits(initialPermits) {}
        
        std::shared_ptr<haxe::Promise<void>> acquire() {
            return std::make_shared<haxe::Promise<void>>(
                [this](auto resolve, auto reject) {
                    std::unique_lock<std::mutex> lock(mutex);
                    if (permits > 0) {
                        permits--;
                        resolve();
                    } else {
                        waitQueue.push([resolve, this]() {
                            permits--;
                            resolve();
                        });
                    }
                }
            );
        }
        
        bool tryAcquire() {
            std::unique_lock<std::mutex> lock(mutex);
            if (permits > 0) {
                permits--;
                return true;
            }
            return false;
        }
        
        void release() {
            std::unique_lock<std::mutex> lock(mutex);
            permits++;
            if (permits > maxPermits) {
                permits = maxPermits;
            }
            
            if (!waitQueue.empty() && permits > 0) {
                auto next = waitQueue.front();
                waitQueue.pop();
                next();
            }
            cv.notify_one();
        }
        
        int availablePermits() const {
            return permits.load();
        }
        
        template<typename T>
        std::shared_ptr<haxe::Promise<T>> withPermit(std::function<std::shared_ptr<haxe::Promise<T>>()> fn) {
            return acquire()->then<T>([this, fn](auto) {
                return fn()->then<T>(
                    [this](T result) {
                        release();
                        return result;
                    }
                )->catchError([this](std::exception_ptr error) -> T {
                    release();
                    std::rethrow_exception(error);
                });
            });
        }
    };
}}
')
@:native("haxe::async::Semaphore")
extern class Semaphore {
    @:native("new haxe::async::Semaphore")
    public function new(initialPermits:Int);
    
    @:native("acquire")
    public function acquire():Promise<Void>;
    
    @:native("tryAcquire")
    public function tryAcquire():Bool;
    
    @:native("release")
    public function release():Void;
    
    @:native("availablePermits")
    public function availablePermits():Int;
    
    @:native("withPermit")
    public function withPermit<T>(fn:Void->Promise<T>):Promise<T>;
}

#else

// Fallback implementation for non-C++ targets
class Semaphore {
    private var permits:Int;
    private var maxPermits:Int;
    private var waitQueue:Array<Void->Void>;
    
    public function new(initialPermits:Int) {
        this.maxPermits = initialPermits;
        this.permits = initialPermits;
        this.waitQueue = [];
    }
    
    public function acquire():Promise<Void> {
        return new Promise<Void>(function(resolve, reject) {
            if (permits > 0) {
                permits--;
                resolve();
            } else {
                waitQueue.push(function() {
                    permits--;
                    resolve();
                });
            }
        });
    }
    
    public function tryAcquire():Bool {
        if (permits > 0) {
            permits--;
            return true;
        }
        return false;
    }
    
    public function release():Void {
        permits++;
        if (permits > maxPermits) {
            permits = maxPermits;
        }
        
        if (waitQueue.length > 0 && permits > 0) {
            var next = waitQueue.shift();
            next();
        }
    }
    
    public function availablePermits():Int {
        return permits;
    }
    
    public function withPermit<T>(fn:Void->Promise<T>):Promise<T> {
        return acquire().then(function(_) {
            return fn().then(
                function(result) {
                    release();
                    return result;
                },
                function(error) {
                    release();
                    throw error;
                }
            );
        });
    }
}

#end