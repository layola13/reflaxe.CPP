package haxe.io;

/**
 * Platform-specific bytes data representation for C++
 */
#if cpp
typedef BytesData = Array<Int>;
#else
typedef BytesData = Dynamic;
#end