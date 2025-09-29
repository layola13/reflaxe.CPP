// =======================================================
// * Reflection
//
// This sub-compiler is used to handle compiling anything
// related to Haxe reflection.
//
// This mainly involves compiling C++ to make the `Type`,
// `Reflect`, `Dynamic` and `Class<T>` types function
// properly.
// =======================================================

package cxxcompiler.subcompilers;

import cxxcompiler.config.Meta;
#if (macro || cxx_runtime)

import haxe.macro.Type;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.PositionHelper;
using reflaxe.helpers.SyntaxHelper;

@:allow(cxxcompiler.Compiler)
@:access(cxxcompiler.Compiler)
class Reflection extends SubCompiler {
	var compiledModules: Array<ModuleType> = [];
	var compiledClasses: Array<ClassType> = [];
	var compiledEnums: Array<EnumType> = [];

	public function addCompiledModuleType(mt: ModuleType) {
		compiledModules.push(mt);
		switch(mt) {
			case TClassDecl(c): addCompiledClassType(c.get());
			case TEnumDecl(e): addCompiledEnumType(e.get());
			case _:
		}
	}

	function addCompiledClassType(cls: ClassType) {
		compiledClasses.push(cls);
	}

	function addCompiledEnumType(enm: EnumType) {
		compiledEnums.push(enm);
	}

	public function compileClassReflection(clsRef: Ref<ClassType>): String {
		final cls = clsRef.get();

		var cpp = TComp.compileClassName(clsRef, PositionHelper.unknownPos(), null, true, true);
		final clsName = cpp;

		var paramsCpp = "";
		if(cls.params.length > 0) {
			paramsCpp = cls.params.map(p -> "typename " + p.name).join(", ");
			cpp += "<" + cls.params.map(p -> p.name).join(", ") + ">";
		}

		final instanceFields = cls.fields.get().map(f -> Main.compileVarName(f.name));
		final staticFields = cls.statics.get().map(f -> Main.compileVarName(f.name));

		final ic = instanceFields.length;
		final sc = staticFields.length;

		final ifCpp = ic == 0 ? "{}" : "{ " + instanceFields.map(f -> "\"" + f + "\"").join(", ") + " }";
		final sfCpp = sc == 0 ? "{}" : "{ " + staticFields.map(f -> "\"" + f + "\"").join(", ") + " }";

		final dynEnabled = DComp.enabled && !cls.hasMeta(Meta.DontGenerateDynamic);

		final fields = ['\"${cls.name}\"', ifCpp, sfCpp, dynEnabled ? "true" : "false"];

		// If the total number of fields is less than 10,
		// place everything on a single line.
		final fieldsCpp = if((ic + sc) >= 10) {
			"\n" + fields.map(f -> f.tab()).join(",\n") + "\n\t";
		} else {
			fields.join(", ");
		}

		final lines = [];
		lines.push("DEFINE_CLASS_TOSTRING");
		if(dynEnabled) lines.push('using Dyn = haxe::Dynamic_${StringTools.replace(clsName, "::", "_")}${cls.params.length > 0 ? '<$cpp>' : ""};');
		lines.push('constexpr static _class_data<${ic}, ${sc}> data {${fieldsCpp}};');

		// Add global namespace prefix :: to avoid ambiguity when the class is in a non-haxe namespace
		final globalCpp = if (cpp.indexOf("::") >= 0 && !StringTools.startsWith(cpp, "::")) "::" + cpp else cpp;
		
		return 'template<${paramsCpp}> struct _class<${globalCpp}> {\n${lines.join("\n").tab()}\n};';
	}

	public function typeUtilHeaderContent() {
		final stringCppType = NameMetaHelper.getNativeNameOverride("String") ?? "std::string";

		IComp.addInclude("array", true, true);
		IComp.addInclude(Includes.StringInclude, true, true);
		IComp.addInclude("memory", true, true);

		return '// ---------------------------------------------------------------------
// haxe::_class<T>
//
// A class used to access reflection information regarding Haxe types.
// ---------------------------------------------------------------------

namespace haxe {

template<typename T>
struct _class;

template<std::size_t sf_size, std::size_t if_size, typename Super = void>
struct _class_data {
	using super_class = _class<Super>;
	constexpr static bool has_super_class = std::is_same<Super, void>::value;

	const char* name = \"<unknown>\";
	const std::array<const char*, sf_size> static_fields;
	const std::array<const char*, if_size> instance_fields;
	bool has_dyn = false;
};

#define DEFINE_CLASS_TOSTRING\\
	$stringCppType toString() {\\
		return $stringCppType(\"Class<\") + data.name + \">\";\\
	}

template<typename T> struct _class {
	constexpr static _class_data<0, 0> data {\"unknown type\", {}, {}};
};

}

// ---------------------------------------------------------------------
// haxe::_unwrap_class
//
// Unwraps Class<T> to T.
// ---------------------------------------------------------------------

namespace haxe {

template<typename T>
struct _unwrap_class {
	using inner = T;
	constexpr static bool iscls = false;
};

template<typename T>
struct _unwrap_class<_class<T>> {
	using inner = typename _unwrap_class<T>::inner;
	constexpr static bool iscls = true;
};

}';
	}
}

#end