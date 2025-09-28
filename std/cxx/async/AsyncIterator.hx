package cxx.async;

#if cpp

import cxx.Function;

/**
 * AsyncIterator for asynchronous iteration over data streams
 */
@:headerInclude("<memory>")
@:headerInclude("<functional>")
@:headerInclude("<optional>")
@:headerCode('
namespace haxe { namespace async {
    template<typename T>
    class AsyncIterator {
    public:
        using NextFunc = std::function<std::shared_ptr<haxe::Promise<std::optional<T>>>()>;
        
    private:
        NextFunc nextFunc;
        
    public:
        AsyncIterator(NextFunc next) : nextFunc(next) {}
        
        std::shared_ptr<haxe::Promise<std::optional<T>>> next() {
            return nextFunc();
        }
        
        template<typename U>
        std::shared_ptr<AsyncIterator<U>> map(std::function<U(T)> mapper) {
            auto self = this;
            return std::make_shared<AsyncIterator<U>>(
                [self, mapper]() -> std::shared_ptr<haxe::Promise<std::optional<U>>> {
                    return self->next()->then<std::optional<U>>([mapper](std::optional<T> value) {
                        if (value.has_value()) {
                            return std::optional<U>(mapper(value.value()));
                        }
                        return std::optional<U>();
                    });
                }
            );
        }
        
        std::shared_ptr<AsyncIterator<T>> filter(std::function<bool(T)> predicate) {
            auto self = this;
            return std::make_shared<AsyncIterator<T>>(
                [self, predicate]() -> std::shared_ptr<haxe::Promise<std::optional<T>>> {
                    std::function<std::shared_ptr<haxe::Promise<std::optional<T>>>()> checkNext;
                    checkNext = [self, predicate, &checkNext]() -> std::shared_ptr<haxe::Promise<std::optional<T>>> {
                        return self->next()->then<std::optional<T>>([predicate, &checkNext](std::optional<T> value) {
                            if (value.has_value()) {
                                if (predicate(value.value())) {
                                    return value;
                                }
                                return checkNext()->get(); // Recursively check next
                            }
                            return std::optional<T>();
                        });
                    };
                    return checkNext();
                }
            );
        }
        
        std::shared_ptr<AsyncIterator<T>> take(int count) {
            auto self = this;
            auto taken = std::make_shared<int>(0);
            return std::make_shared<AsyncIterator<T>>(
                [self, count, taken]() -> std::shared_ptr<haxe::Promise<std::optional<T>>> {
                    if (*taken >= count) {
                        return haxe::Promise<std::optional<T>>::resolve(std::optional<T>());
                    }
                    (*taken)++;
                    return self->next();
                }
            );
        }
        
        std::shared_ptr<haxe::Promise<std::vector<T>>> toArray() {
            auto self = this;
            auto results = std::make_shared<std::vector<T>>();
            
            std::function<std::shared_ptr<haxe::Promise<std::vector<T>>>()> collectAll;
            collectAll = [self, results, &collectAll]() -> std::shared_ptr<haxe::Promise<std::vector<T>>> {
                return self->next()->then<std::vector<T>>([results, &collectAll](std::optional<T> value) {
                    if (value.has_value()) {
                        results->push_back(value.value());
                        return collectAll();
                    }
                    return *results;
                });
            };
            
            return collectAll();
        }
        
        template<typename U>
        std::shared_ptr<haxe::Promise<U>> reduce(std::function<U(U, T)> reducer, U initial) {
            auto self = this;
            auto accumulator = std::make_shared<U>(initial);
            
            std::function<std::shared_ptr<haxe::Promise<U>>()> reduceNext;
            reduceNext = [self, reducer, accumulator, &reduceNext]() -> std::shared_ptr<haxe::Promise<U>> {
                return self->next()->then<U>([reducer, accumulator, &reduceNext](std::optional<T> value) {
                    if (value.has_value()) {
                        *accumulator = reducer(*accumulator, value.value());
                        return reduceNext();
                    }
                    return *accumulator;
                });
            };
            
            return reduceNext();
        }
        
        static std::shared_ptr<AsyncIterator<T>> from(std::vector<T> items) {
            auto index = std::make_shared<size_t>(0);
            auto data = std::make_shared<std::vector<T>>(items);
            
            return std::make_shared<AsyncIterator<T>>(
                [index, data]() -> std::shared_ptr<haxe::Promise<std::optional<T>>> {
                    if (*index < data->size()) {
                        auto value = (*data)[(*index)++];
                        return haxe::Promise<std::optional<T>>::resolve(std::optional<T>(value));
                    }
                    return haxe::Promise<std::optional<T>>::resolve(std::optional<T>());
                }
            );
        }
    };
}}
')
@:native("haxe::async::AsyncIterator")
extern class AsyncIterator<T> {
    /**
     * Get the next value from the iterator
     */
    @:native("next")
    public function next():Promise<Null<T>>;
    
    /**
     * Transform each value using a mapping function
     */
    @:native("map")
    public function map<U>(mapper:T->U):AsyncIterator<U>;
    
    /**
     * Filter values based on a predicate
     */
    @:native("filter")
    public function filter(predicate:T->Bool):AsyncIterator<T>;
    
    /**
     * Take only the first n values
     */
    @:native("take")
    public function take(count:Int):AsyncIterator<T>;
    
    /**
     * Collect all values into an array
     */
    @:native("toArray")
    public function toArray():Promise<Array<T>>;
    
    /**
     * Reduce values to a single result
     */
    @:native("reduce")
    public function reduce<U>(reducer:(U, T)->U, initial:U):Promise<U>;
    
    /**
     * Create an AsyncIterator from an array
     */
    @:native("haxe::async::AsyncIterator<T>::from")
    public static function from<T>(items:Array<T>):AsyncIterator<T>;
}

#else

// Fallback implementation for non-C++ targets
class AsyncIterator<T> {
    private var nextFunc:()->Promise<Null<T>>;
    
    public function new(next:()->Promise<Null<T>>) {
        this.nextFunc = next;
    }
    
    public function next():Promise<Null<T>> {
        return nextFunc();
    }
    
    public function map<U>(mapper:T->U):AsyncIterator<U> {
        return new AsyncIterator(() -> {
            return next().then(value -> {
                return value != null ? mapper(value) : null;
            });
        });
    }
    
    public function filter(predicate:T->Bool):AsyncIterator<T> {
        function checkNext():Promise<Null<T>> {
            return next().then(value -> {
                if (value != null) {
                    if (predicate(value)) {
                        return Promise.resolve(value);
                    }
                    return checkNext();
                }
                return Promise.resolve(null);
            });
        }
        return new AsyncIterator(checkNext);
    }
    
    public function take(count:Int):AsyncIterator<T> {
        var taken = 0;
        return new AsyncIterator(() -> {
            if (taken >= count) {
                return Promise.resolve(null);
            }
            taken++;
            return next();
        });
    }
    
    public function toArray():Promise<Array<T>> {
        var results:Array<T> = [];
        
        function collectAll():Promise<Array<T>> {
            return next().then(value -> {
                if (value != null) {
                    results.push(value);
                    return collectAll();
                }
                return Promise.resolve(results);
            });
        }
        
        return collectAll();
    }
    
    public function reduce<U>(reducer:(U, T)->U, initial:U):Promise<U> {
        var accumulator = initial;
        
        function reduceNext():Promise<U> {
            return next().then(value -> {
                if (value != null) {
                    accumulator = reducer(accumulator, value);
                    return reduceNext();
                }
                return Promise.resolve(accumulator);
            });
        }
        
        return reduceNext();
    }
    
    public static function from<T>(items:Array<T>):AsyncIterator<T> {
        var index = 0;
        return new AsyncIterator(() -> {
            if (index < items.length) {
                return Promise.resolve(items[index++]);
            }
            return Promise.resolve(null);
        });
    }
}

#end