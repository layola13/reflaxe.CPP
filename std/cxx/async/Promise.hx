package cxx.async;

/**
	Promise implementation for async/await support in reflaxe.CPP
	This is the core type returned by @:async functions and consumed by @:await expressions
**/
@:cppFileCode('
#include <memory>
#include <functional>
#include <mutex>
#include <condition_variable>
#include <exception>
#include <thread>
#include <atomic>
#include <vector>
')
@:forward
@:nativeGen
@:include("cxx_async_Promise.h")
@:noInclude
extern class Promise<T> {
	/**
		Create a new Promise with an executor function
	**/
	@:native("std::make_shared<cxx::async::PromiseImpl>")
	public static function create<T>(executor:(resolve:(value:T)->Void, reject:(error:Any)->Void)->Void):Promise<T>;
	
	/**
		Create an immediately resolved Promise
	**/
	public static function resolve<T>(value:T):Promise<T>;
	
	/**
		Create an immediately rejected Promise
	**/
	public static function reject<T>(error:Any):Promise<T>;
	
	/**
		Wait for all promises to complete
	**/
	public static function all<T>(promises:Array<Promise<T>>):Promise<Array<T>>;
	
	/**
		Race multiple promises - return first to resolve or reject
	**/
	public static function race<T>(promises:Array<Promise<T>>):Promise<T>;
}

/**
	Internal implementation of Promise
	This is what the shared_ptr points to
**/
@:nativeGen
@:native("cxx::async::PromiseImpl")
@:include("cxx_async_Promise.h")
private extern class PromiseImpl<T> {
	/**
		Constructor that takes an executor function
	**/
	public function new(executor:(resolve:(value:T)->Void, reject:(error:Any)->Void)->Void);
	
	/**
		Wait for the promise to resolve synchronously
		This is what @:await uses internally
	**/
	public function wait():T;
	
	/**
		Chain a callback for when the promise resolves
	**/
	public function then<U>(onFulfilled:(value:T)->U):Promise<U>;
	
	/**
		Handle promise rejection
	**/
	public function catchError(onRejected:(error:Any)->Void):Promise<T>;
	
	/**
		Get result without blocking (returns null if not ready)
	**/
	public function tryGetResult():Null<T>;
	
	/**
		Check if the promise has been resolved
	**/
	public function isResolved():Bool;
	
	/**
		Check if the promise has been rejected
	**/
	public function isRejected():Bool;
}

/**
	Timer utility for creating delayed promises
**/
@:native("cxx::async::Timer")  
@:include("cxx_async_Timer.h")
extern class Timer {
	/**
		Create a promise that resolves after the specified delay (in milliseconds)
	**/
	public static function delay(ms:Int):Promise<Void>;
}