#pragma once

#include <memory>
#include <functional>
#include <mutex>
#include <condition_variable>
#include <exception>
#include <thread>
#include <atomic>
#include <vector>
#include <any>
#include <deque>

namespace cxx {
namespace async {

template<typename T>
class PromiseImpl;

template<typename T>
using Promise = std::shared_ptr<PromiseImpl<T>>;

template<typename T>
class PromiseImpl : public std::enable_shared_from_this<PromiseImpl<T>> {
private:
    mutable std::mutex mutex_;
    mutable std::condition_variable cv_;
    mutable bool is_resolved_ = false;
    mutable bool is_rejected_ = false;
    mutable T value_{};
    mutable std::exception_ptr error_;
    
    std::vector<std::function<void(T)>> then_callbacks_;
    std::vector<std::function<void(std::exception_ptr)>> catch_callbacks_;
    
public:
    // Constructor with executor
    PromiseImpl(std::function<void(std::function<void(T)>, std::function<void(std::any)>)> executor) {
        // Execute asynchronously
        std::thread([this, executor]() {
            try {
                executor(
                    [this](T val) { this->_resolve(val); },
                    [this](std::any err) { this->_reject(err); }
                );
            } catch (...) {
                this->_reject(std::current_exception());
            }
        }).detach();
    }
    
    // Internal resolve function (private to avoid conflict with static method)
    void _resolve(T val) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (is_resolved_ || is_rejected_) return;
            
            value_ = val;
            is_resolved_ = true;
        }
        cv_.notify_all();
        
        // Execute then callbacks
        for (auto& callback : then_callbacks_) {
            try {
                callback(value_);
            } catch (...) {
                // Ignore callback errors for now
            }
        }
    }
    
    // Internal reject function (private to avoid conflict with static method)
    void _reject(std::any err) {
        std::exception_ptr ex_ptr;
        
        // Convert std::any to exception_ptr if needed
        try {
            if (err.type() == typeid(std::exception_ptr)) {
                ex_ptr = std::any_cast<std::exception_ptr>(err);
            } else {
                // Create a generic exception
                ex_ptr = std::make_exception_ptr(std::runtime_error("Promise rejected"));
            }
        } catch (...) {
            ex_ptr = std::current_exception();
        }
        
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (is_resolved_ || is_rejected_) return;
            
            error_ = ex_ptr;
            is_rejected_ = true;
        }
        cv_.notify_all();
        
        // Execute catch callbacks
        for (auto& callback : catch_callbacks_) {
            callback(error_);
        }
    }
    
    // Wait for promise to resolve (blocking)
    T wait() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this] { return is_resolved_ || is_rejected_; });
        
        if (is_rejected_) {
            if (error_) {
                std::rethrow_exception(error_);
            }
            throw std::runtime_error("Promise rejected");
        }
        
        return value_;
    }
    
    // Chain with then
    template<typename U>
    Promise<U> then(std::function<U(T)> on_fulfilled) {
        auto self = this->shared_from_this();
        
        return std::make_shared<PromiseImpl<U>>(
            [self, on_fulfilled](auto resolve, auto reject) {
                if (self->is_resolved_) {
                    try {
                        resolve(on_fulfilled(self->value_));
                    } catch (...) {
                        reject(std::current_exception());
                    }
                } else if (!self->is_rejected_) {
                    self->then_callbacks_.push_back([resolve, reject, on_fulfilled](T val) {
                        try {
                            resolve(on_fulfilled(val));
                        } catch (...) {
                            reject(std::current_exception());
                        }
                    });
                    
                    self->catch_callbacks_.push_back([reject](std::exception_ptr err) {
                        reject(err);
                    });
                }
            }
        );
    }
    
    // Handle errors
    Promise<T> catchError(std::function<void(std::any)> on_rejected) {
        auto self = this->shared_from_this();
        
        return std::make_shared<PromiseImpl<T>>(
            [self, on_rejected](auto resolve, auto reject) {
                if (self->is_rejected_) {
                    try {
                        on_rejected(self->error_);
                    } catch (...) {
                        reject(std::current_exception());
                    }
                } else if (!self->is_resolved_) {
                    self->catch_callbacks_.push_back([on_rejected, reject](std::exception_ptr err) {
                        try {
                            on_rejected(err);
                        } catch (...) {
                            reject(std::current_exception());
                        }
                    });
                    
                    // Also propagate successful resolution
                    self->then_callbacks_.push_back([resolve](T val) {
                        resolve(val);
                    });
                } else {
                    // Already resolved, just pass through
                    resolve(self->value_);
                }
            }
        );
    }
    
    // Check if resolved
    bool isResolved() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return is_resolved_;
    }
    
    // Check if rejected
    bool isRejected() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return is_rejected_;
    }
    
    // Try to get result without blocking
    T tryGetResult() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (is_resolved_) {
            return value_;
        }
        return T{};
    }
    
    // Static factory methods
    static Promise<T> resolve(T value) {
        return std::make_shared<PromiseImpl<T>>(
            [value](auto resolve, auto reject) {
                resolve(value);
            }
        );
    }
    
    static Promise<T> reject(std::any error) {
        return std::make_shared<PromiseImpl<T>>(
            [error](auto resolve, auto reject) {
                reject(error);
            }
        );
    }
    
    // Promise.all implementation
    static Promise<std::shared_ptr<std::deque<T>>> all(std::shared_ptr<std::deque<Promise<T>>> promises) {
        return std::make_shared<PromiseImpl<std::shared_ptr<std::deque<T>>>>(
            [promises](auto resolve, auto reject) {
                if (promises->empty()) {
                    resolve(std::make_shared<std::deque<T>>());
                    return;
                }
                
                auto results = std::make_shared<std::deque<T>>(promises->size());
                auto remaining = std::make_shared<std::atomic<int>>(promises->size());
                
                for (size_t i = 0; i < promises->size(); ++i) {
                    (*promises)[i]->then([results, remaining, resolve, i](T val) {
                        (*results)[i] = val;
                        if (--(*remaining) == 0) {
                            resolve(results);
                        }
                        return val;
                    })->catchError([reject](std::any err) {
                        reject(err);
                    });
                }
            }
        );
    }
    
    // Promise.race implementation
    static Promise<T> race(std::shared_ptr<std::deque<Promise<T>>> promises) {
        return std::make_shared<PromiseImpl<T>>(
            [promises](auto resolve, auto reject) {
                auto done = std::make_shared<std::atomic<bool>>(false);
                
                for (auto& promise : *promises) {
                    promise->then([done, resolve](T val) {
                        bool expected = false;
                        if (done->compare_exchange_strong(expected, true)) {
                            resolve(val);
                        }
                        return val;
                    })->catchError([done, reject](std::any err) {
                        bool expected = false;
                        if (done->compare_exchange_strong(expected, true)) {
                            reject(err);
                        }
                    });
                }
            }
        );
    }
};

// Specialization for void
template<>
class PromiseImpl<void> : public std::enable_shared_from_this<PromiseImpl<void>> {
private:
    mutable std::mutex mutex_;
    mutable std::condition_variable cv_;
    mutable bool is_resolved_ = false;
    mutable bool is_rejected_ = false;
    mutable std::exception_ptr error_;
    
    std::vector<std::function<void()>> then_callbacks_;
    std::vector<std::function<void(std::exception_ptr)>> catch_callbacks_;
    
public:
    PromiseImpl(std::function<void(std::function<void()>, std::function<void(std::any)>)> executor) {
        std::thread([this, executor]() {
            try {
                executor(
                    [this]() { this->_resolve(); },
                    [this](std::any err) { this->_reject(err); }
                );
            } catch (...) {
                this->_reject(std::current_exception());
            }
        }).detach();
    }
    
    // Internal resolve function (private to avoid conflict with static method)
    void _resolve() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (is_resolved_ || is_rejected_) return;
            is_resolved_ = true;
        }
        cv_.notify_all();
        
        for (auto& callback : then_callbacks_) {
            try {
                callback();
            } catch (...) {
                // Ignore callback errors
            }
        }
    }
    
    // Internal reject function (private to avoid conflict with static method)
    void _reject(std::any err) {
        std::exception_ptr ex_ptr;
        try {
            if (err.type() == typeid(std::exception_ptr)) {
                ex_ptr = std::any_cast<std::exception_ptr>(err);
            } else {
                ex_ptr = std::make_exception_ptr(std::runtime_error("Promise rejected"));
            }
        } catch (...) {
            ex_ptr = std::current_exception();
        }
        
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (is_resolved_ || is_rejected_) return;
            error_ = ex_ptr;
            is_rejected_ = true;
        }
        cv_.notify_all();
        
        for (auto& callback : catch_callbacks_) {
            callback(error_);
        }
    }
    
    void wait() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this] { return is_resolved_ || is_rejected_; });
        
        if (is_rejected_) {
            if (error_) {
                std::rethrow_exception(error_);
            }
            throw std::runtime_error("Promise rejected");
        }
    }
    
    bool isResolved() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return is_resolved_;
    }
    
    bool isRejected() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return is_rejected_;
    }
    
    static Promise<void> resolve() {
        return std::make_shared<PromiseImpl<void>>(
            [](auto resolve, auto reject) {
                resolve();
            }
        );
    }
    
    static Promise<void> reject(std::any error) {
        return std::make_shared<PromiseImpl<void>>(
            [error](auto resolve, auto reject) {
                reject(error);
            }
        );
    }
};

// Timer utility
class Timer {
public:
    static Promise<void> delay(int milliseconds) {
        return std::make_shared<PromiseImpl<void>>(
            [milliseconds](auto resolve, auto reject) {
                std::thread([milliseconds, resolve]() {
                    std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
                    resolve();
                }).detach();
            }
        );
    }
};

} // namespace async
} // namespace cxx