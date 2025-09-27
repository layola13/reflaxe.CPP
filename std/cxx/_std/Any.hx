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
	@:nativeFunctionCode("([&]() -> std::string {
		try {
			// Try to cast to common types and return their string representation
			if ({this}.type() == typeid(int)) {
				return std::to_string(std::any_cast<int>({this}));
			} else if ({this}.type() == typeid(double)) {
				return std::to_string(std::any_cast<double>({this}));
			} else if ({this}.type() == typeid(float)) {
				return std::to_string(std::any_cast<float>({this}));
			} else if ({this}.type() == typeid(std::string)) {
				return std::any_cast<std::string>({this});
			} else if ({this}.type() == typeid(bool)) {
				return std::any_cast<bool>({this}) ? \"true\" : \"false\";
			} else {
				return \"<Any(\" + std::string({this}.type().name()) + \")>\";
			}
		} catch (const std::bad_any_cast& e) {
			return \"<Any(\" + std::string({this}.type().name()) + \")>\";
		}
	})()")
	extern function toString(): String;

	@:nativeFunctionCode("{this}.type()")
	extern function type(): cxx.std.TypeInfo;
}
