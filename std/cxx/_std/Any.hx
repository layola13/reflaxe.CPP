package;

@:cxxStd
@:haxeStd
@:nativeName("std::any", "Any")
@:include("any", true)
@:forward.variance
@:valueType
extern abstract Any(Dynamic) {
	@:noCompletion
	@:to
	@:nativeFunctionCode("std::any_cast<{type0}>({this})")
	@:makeThisNotNull
	@:include("any", true)
	extern function __promote<T>(): T;

	@:noCompletion
	@:from
	extern inline static function __cast<T>(value: T): Any {
		return cast value;
	}

	@:noCompletion
	@:include("string", true)
	@:include("optional", true)
	@:include("typeinfo", true)
	@:nativeFunctionCode("haxe::DynamicToString::ToString({this})")
	extern function toString(): String;

	@:nativeFunctionCode("{this}.type()")
	extern function type(): cxx.std.TypeInfo;
}